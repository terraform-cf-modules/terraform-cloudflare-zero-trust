# Submodule: tunnel

Cloudflared tunnels, their remote configuration, private network routes and virtual networks.

| Terraform resource | v4 name | Purpose |
|--------------------|---------|---------|
| `cloudflare_zero_trust_tunnel_cloudflared` | `cloudflare_tunnel` | The tunnel itself |
| `cloudflare_zero_trust_tunnel_cloudflared_config` | `cloudflare_tunnel_config` | Remotely managed ingress rules |
| `cloudflare_zero_trust_tunnel_cloudflared_route` | `cloudflare_tunnel_route` | Private CIDR advertised through a tunnel |
| `cloudflare_zero_trust_tunnel_cloudflared_virtual_network` | `cloudflare_tunnel_virtual_network` | Namespace for overlapping CIDRs |

## Who owns the configuration

`config_src = "cloudflare"` means the ingress rules live in the Cloudflare dashboard and API, and this module
manages them through `config`. `config_src = "local"` means the `cloudflared` process reads its own
`config.yml`, and setting `config` here would fight it. The module rejects that combination.

## Ingress rules are ordered and need a catch all

`config.ingress` is an ordered list. The first rule whose hostname and path match wins. The final rule must be a
catch all with no hostname, otherwise cloudflared refuses the configuration:

```hcl
config = {
  ingress = [
    { hostname = "app.example.com", service = "http://localhost:8080" },
    { hostname = "ssh.example.com", service = "ssh://localhost:22" },
    { service = "http_status:404" },
  ]
}
```

Both rules are enforced by `validation` blocks on `var.tunnels`.

## Secrets

`tunnel_secret` is the credential cloudflared authenticates with. Leave it null and Cloudflare generates one.
`tunnel_secrets` and `tunnel_tokens` outputs are marked `sensitive = true`; `tunnel_tokens` is the base64 blob
that `cloudflared tunnel run --token` expects.

## DNS

This module does not create DNS records. Point a proxied CNAME at the value in `tunnel_cnames`, which is
`<tunnel id>.cfargotunnel.com`.

## Usage

```hcl
module "tunnel" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/tunnel"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  tunnels = {
    edge = {
      name       = "edge"
      config_src = "cloudflare"
      config = {
        ingress = [
          { hostname = "app.example.com", service = "http://localhost:8080" },
          { service = "http_status:404" },
        ]
      }
    }
  }

  routes = {
    private = {
      tunnel_key = "edge"
      network    = "10.0.0.0/16"
      comment    = "Production VPC"
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
