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
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the tunnels. Required, every tunnel resource is account scoped. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_routes"></a> [routes](#input\_routes) | Private network routes advertised through a tunnel, keyed by a stable identifier.<br/><br/>Set `tunnel_key` to point at a tunnel created by this same module, or `tunnel_id` to point at an existing one.<br/>Likewise `virtual_network_key` for a virtual network created here, or `virtual_network_id` for an existing one. | <pre>map(object({<br/>    network             = string<br/>    comment             = optional(string)<br/>    tunnel_key          = optional(string)<br/>    tunnel_id           = optional(string)<br/>    virtual_network_key = optional(string)<br/>    virtual_network_id  = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tunnels"></a> [tunnels](#input\_tunnels) | Cloudflared tunnels, keyed by a stable identifier.<br/><br/>`config_src` decides who owns the ingress rules. Use `cloudflare` to manage them here through `config`,<br/>or `local` when the cloudflared process reads its own config file, in which case leave `config` null.<br/><br/>`tunnel_secret` is a base64 encoded 32 byte secret. Leave it null and Cloudflare generates one. | <pre>map(object({<br/>    name          = optional(string)<br/>    config_src    = optional(string, "cloudflare")<br/>    tunnel_secret = optional(string)<br/><br/>    config = optional(object({<br/>      ingress = optional(list(object({<br/>        service  = string<br/>        hostname = optional(string)<br/>        path     = optional(string)<br/>        origin_request = optional(object({<br/>          access = optional(object({<br/>            aud_tag   = list(string)<br/>            team_name = string<br/>            required  = optional(bool)<br/>          }))<br/>          ca_pool                  = optional(string)<br/>          connect_timeout          = optional(number)<br/>          disable_chunked_encoding = optional(bool)<br/>          http2_origin             = optional(bool)<br/>          http_host_header         = optional(string)<br/>          keep_alive_connections   = optional(number)<br/>          keep_alive_timeout       = optional(number)<br/>          match_sn_ito_host        = optional(bool)<br/>          no_happy_eyeballs        = optional(bool)<br/>          no_tls_verify            = optional(bool)<br/>          origin_server_name       = optional(string)<br/>          proxy_type               = optional(string)<br/>          tcp_keep_alive           = optional(number)<br/>          tls_timeout              = optional(number)<br/>        }))<br/>      })), [])<br/><br/>      origin_request = optional(object({<br/>        access = optional(object({<br/>          aud_tag   = list(string)<br/>          team_name = string<br/>          required  = optional(bool)<br/>        }))<br/>        ca_pool                  = optional(string)<br/>        connect_timeout          = optional(number)<br/>        disable_chunked_encoding = optional(bool)<br/>        http2_origin             = optional(bool)<br/>        http_host_header         = optional(string)<br/>        keep_alive_connections   = optional(number)<br/>        keep_alive_timeout       = optional(number)<br/>        match_sn_ito_host        = optional(bool)<br/>        no_happy_eyeballs        = optional(bool)<br/>        no_tls_verify            = optional(bool)<br/>        origin_server_name       = optional(string)<br/>        proxy_type               = optional(string)<br/>        tcp_keep_alive           = optional(number)<br/>        tls_timeout              = optional(number)<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_virtual_networks"></a> [virtual\_networks](#input\_virtual\_networks) | Tunnel virtual networks, keyed by a stable identifier. Virtual networks let overlapping private CIDRs coexist in one account. | <pre>map(object({<br/>    name               = optional(string)<br/>    comment            = optional(string)<br/>    is_default_network = optional(bool)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | Map of route key to route ID. |
| <a name="output_routes"></a> [routes](#output\_routes) | Full route objects, keyed by the same keys as var.routes. |
| <a name="output_tunnel_cnames"></a> [tunnel\_cnames](#output\_tunnel\_cnames) | Map of tunnel key to the CNAME target a DNS record should point at to route traffic into the tunnel. |
| <a name="output_tunnel_config_ids"></a> [tunnel\_config\_ids](#output\_tunnel\_config\_ids) | Map of tunnel key to the ID of its remote configuration, for tunnels with config\_src = cloudflare. |
| <a name="output_tunnel_configs"></a> [tunnel\_configs](#output\_tunnel\_configs) | Full tunnel configuration objects, keyed by tunnel key. |
| <a name="output_tunnel_ids"></a> [tunnel\_ids](#output\_tunnel\_ids) | Map of tunnel key to tunnel ID. |
| <a name="output_tunnel_secrets"></a> [tunnel\_secrets](#output\_tunnel\_secrets) | Map of tunnel key to tunnel secret. Sensitive, this is the credential cloudflared authenticates with. |
| <a name="output_tunnel_tokens"></a> [tunnel\_tokens](#output\_tunnel\_tokens) | Map of tunnel key to the base64 connector token cloudflared consumes as `cloudflared tunnel run --token`. Null for any tunnel whose secret Cloudflare generated, because the API does not return it. Sensitive. |
| <a name="output_tunnels"></a> [tunnels](#output\_tunnels) | Full tunnel objects. Marked sensitive because each carries tunnel\_secret. |
| <a name="output_virtual_network_ids"></a> [virtual\_network\_ids](#output\_virtual\_network\_ids) | Map of virtual network key to virtual network ID. |
| <a name="output_virtual_networks"></a> [virtual\_networks](#output\_virtual\_networks) | Full virtual network objects, keyed by the same keys as var.virtual\_networks. |
<!-- END_TF_DOCS -->
