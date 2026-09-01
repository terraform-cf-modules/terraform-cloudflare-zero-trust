# Feature example: a Cloudflared tunnel that publishes one HTTP origin and
# advertises a private CIDR, with an Access application in front of it.
#
# This is the combination that is easiest to get wrong by hand:
#
#   * ingress rules are ordered and the last one must be a catch all,
#   * a private CIDR needs a route, not an ingress rule,
#   * the route needs a virtual network when CIDRs overlap across sites,
#   * the DNS record that fronts the tunnel is a proxied CNAME to
#     <tunnel id>.cfargotunnel.com, which this module exposes but does not create.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id

  # Two virtual networks so the same RFC1918 range can exist in two sites.
  tunnel_virtual_networks = {
    london = {
      name               = "london"
      comment            = "London office"
      is_default_network = true
    }
    frankfurt = {
      name    = "frankfurt"
      comment = "Frankfurt office"
    }
  }

  tunnels = {
    london = {
      name       = "london-edge"
      config_src = "cloudflare"

      config = {
        # Defaults applied to every ingress rule that does not override them.
        origin_request = {
          connect_timeout = 30
          no_tls_verify   = false
        }

        ingress = [
          # Order matters. The first rule that matches wins, so the narrow
          # path rule has to come before the catch all for the same hostname.
          {
            hostname = var.application_domain
            path     = "/metrics"
            service  = "http://127.0.0.1:9090"
          },
          {
            hostname = var.application_domain
            service  = "http://127.0.0.1:8080"
            origin_request = {
              http_host_header = var.application_domain
              connect_timeout  = 10
            }
          },
          # The catch all. cloudflared refuses a configuration without it.
          {
            service = "http_status:404"
          },
        ]
      }
    }

    frankfurt = {
      name       = "frankfurt-edge"
      config_src = "local" # cloudflared reads its own config.yml on the host
    }
  }

  # Private CIDRs reachable through the tunnel. These are routes, not ingress
  # rules: WARP clients reach them by IP, no hostname involved.
  tunnel_routes = {
    london_private = {
      tunnel_key          = "london"
      virtual_network_key = "london"
      network             = "10.10.0.0/16"
      comment             = "London private range"
    }
    frankfurt_private = {
      tunnel_key          = "frankfurt"
      virtual_network_key = "frankfurt"
      network             = "10.10.0.0/16"
      comment             = "Frankfurt private range, deliberately overlapping"
    }
  }

  # Access in front of the hostname the tunnel publishes.
  identity_providers = {
    otp = {
      name   = "One time PIN"
      type   = "onetimepin"
      config = {}
    }
  }

  access_policies = {
    allow_staff = {
      name             = "Allow staff"
      decision         = "allow"
      session_duration = "24h"
      include          = [{ email_domain = { domain = var.email_domain } }]
    }
  }

  access_applications = {
    app = {
      name             = "Tunnelled app"
      type             = "self_hosted"
      domain           = var.application_domain
      session_duration = "24h"
      destinations     = [{ type = "public", uri = var.application_domain }]
      policy_keys      = ["allow_staff"]
      allowed_idp_keys = ["otp"]
    }
  }
}
