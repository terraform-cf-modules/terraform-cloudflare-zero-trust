output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "tunnel_ids" {
  description = "Map of tunnel key to tunnel ID."
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared.this : k => v.id }
}

output "tunnel_cnames" {
  description = "Map of tunnel key to the CNAME target a DNS record should point at to route traffic into the tunnel."
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared.this : k => "${v.id}.cfargotunnel.com" }
}

output "tunnel_secrets" {
  description = "Map of tunnel key to tunnel secret. Sensitive, this is the credential cloudflared authenticates with."
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared.this : k => v.tunnel_secret }
  sensitive   = true
}

output "tunnel_tokens" {
  description = "Map of tunnel key to the base64 connector token cloudflared consumes as `cloudflared tunnel run --token`. Null for any tunnel whose secret Cloudflare generated, because the API does not return it. Sensitive."
  value = {
    for k, v in cloudflare_zero_trust_tunnel_cloudflared.this :
    k => v.tunnel_secret == null ? null : base64encode(jsonencode({
      a = v.account_tag
      t = v.id
      s = v.tunnel_secret
    }))
  }
  sensitive = true
}

output "tunnels" {
  description = "Full tunnel objects. Marked sensitive because each carries tunnel_secret."
  value       = cloudflare_zero_trust_tunnel_cloudflared.this
  sensitive   = true
}

output "tunnel_config_ids" {
  description = "Map of tunnel key to the ID of its remote configuration, for tunnels with config_src = cloudflare."
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared_config.this : k => v.id }
}

output "tunnel_configs" {
  description = "Full tunnel configuration objects, keyed by tunnel key."
  value       = cloudflare_zero_trust_tunnel_cloudflared_config.this
}

output "virtual_network_ids" {
  description = "Map of virtual network key to virtual network ID."
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this : k => v.id }
}

output "virtual_networks" {
  description = "Full virtual network objects, keyed by the same keys as var.virtual_networks."
  value       = cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this
}

output "route_ids" {
  description = "Map of route key to route ID."
  value       = { for k, v in cloudflare_zero_trust_tunnel_cloudflared_route.this : k => v.id }
}

output "routes" {
  description = "Full route objects, keyed by the same keys as var.routes."
  value       = cloudflare_zero_trust_tunnel_cloudflared_route.this
}
