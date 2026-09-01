output "tunnel_ids" {
  description = "Map of tunnel key to tunnel ID."
  value       = module.this.tunnel_ids
}

output "tunnel_cnames" {
  description = "CNAME target for each tunnel. Point a proxied DNS record at this value to publish the hostname."
  value       = module.this.tunnel_cnames
}

output "tunnel_route_ids" {
  description = "Map of route key to route ID."
  value       = module.this.tunnel_route_ids
}

output "tunnel_virtual_network_ids" {
  description = "Map of virtual network key to virtual network ID."
  value       = module.this.tunnel_virtual_network_ids
}

output "tunnel_tokens" {
  description = "Connector token for each tunnel, for `cloudflared tunnel run --token`. Null when Cloudflare generated the secret."
  value       = module.this.tunnel_tokens
  sensitive   = true
}

output "access_application_ids" {
  description = "Map of application key to application ID."
  value       = module.this.access_application_ids
}
