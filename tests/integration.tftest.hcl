# Applies against a real Cloudflare test account.
# Runs on a schedule and on manual dispatch only, never on pull requests,
# because fork pull requests cannot read organisation secrets.
#
# Deliberately avoids every per account singleton (Gateway settings, Gateway
# logging, device settings, the default WARP profile, DLP settings) so a test
# run cannot clobber the shared test account's configuration.

variables {
  account_id = null # supplied by TF_VAR_account_id
  zone_id    = null # supplied by TF_VAR_zone_id
}

run "apply_and_destroy" {
  command = apply

  variables {
    identity_providers = {
      otp = {
        name   = "tftest one time pin"
        type   = "onetimepin"
        config = {}
      }
    }

    service_tokens = {
      ci = {
        name     = "tftest-ci"
        duration = "8760h"
      }
    }

    access_groups = {
      staff = {
        name    = "tftest staff"
        include = [{ email_domain = { domain = "example.com" } }]
      }
    }

    access_policies = {
      allow_staff = {
        name               = "tftest allow staff"
        decision           = "allow"
        session_duration   = "24h"
        include            = []
        include_group_keys = ["staff"]
      }
      allow_ci = {
        name                       = "tftest allow ci"
        decision                   = "non_identity"
        include                    = []
        include_service_token_keys = ["ci"]
      }
    }

    access_applications = {
      intranet = {
        name             = "tftest intranet"
        type             = "self_hosted"
        domain           = "tftest-intranet.example.com"
        session_duration = "24h"
        destinations     = [{ type = "public", uri = "tftest-intranet.example.com" }]
        policy_keys      = ["allow_staff", "allow_ci"]
        allowed_idp_keys = ["otp"]
      }
    }

    gateway_lists = {
      blocked = {
        name  = "tftest blocked domains"
        type  = "DOMAIN"
        items = [{ value = "malware.example" }]
      }
    }

    gateway_policies = {
      block = {
        name       = "tftest block"
        action     = "block"
        filters    = ["dns"]
        precedence = 9000
        traffic    = "any(dns.domains[*] == \"malware.example\")"
      }
    }

    tunnels = {
      edge = {
        name       = "tftest-edge"
        config_src = "cloudflare"
        config = {
          ingress = [
            { hostname = "tftest-app.example.com", service = "http://localhost:8080" },
            { service = "http_status:404" },
          ]
        }
      }
    }
  }

  assert {
    condition     = output.enabled == true
    error_message = "Module did not report enabled after apply."
  }

  assert {
    condition     = length(output.access_application_ids) == 1
    error_message = "Expected exactly one Access application after apply."
  }

  assert {
    condition     = alltrue([for id in values(output.access_policy_ids) : length(id) == 36])
    error_message = "Access policy IDs should be UUIDs returned by the API."
  }

  assert {
    condition     = length(output.tunnel_ids) == 1
    error_message = "Expected exactly one tunnel after apply."
  }

  assert {
    condition     = alltrue([for c in values(output.tunnel_cnames) : endswith(c, ".cfargotunnel.com")])
    error_message = "Tunnel CNAME targets should end in .cfargotunnel.com."
  }

  assert {
    condition     = length(output.gateway_policy_ids) == 1
    error_message = "Expected exactly one Gateway policy after apply."
  }
}
