output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "list_ids" {
  description = "Map of list key to list ID. Gateway expressions reference a list by that ID through cf.list."
  value       = { for k, v in cloudflare_zero_trust_list.this : k => v.id }
}

output "lists" {
  description = "Full Zero Trust list objects, keyed by the same keys as var.lists."
  value       = cloudflare_zero_trust_list.this
}

output "policy_ids" {
  description = "Map of Gateway policy key to policy ID."
  value       = { for k, v in cloudflare_zero_trust_gateway_policy.this : k => v.id }
}

output "policies" {
  description = "Full Gateway policy objects, keyed by the same keys as var.policies."
  value       = cloudflare_zero_trust_gateway_policy.this
}

output "settings" {
  description = "The account wide Gateway settings object, or null when this module does not manage it."
  value       = one(cloudflare_zero_trust_gateway_settings.this)
}

output "logging" {
  description = "The account wide Gateway logging object, or null when this module does not manage it."
  value       = one(cloudflare_zero_trust_gateway_logging.this)
}

output "certificate_ids" {
  description = "Map of Gateway certificate key to certificate ID."
  value       = { for k, v in cloudflare_zero_trust_gateway_certificate.this : k => v.id }
}

output "certificates" {
  description = "Full Gateway certificate objects, keyed by the same keys as var.certificates."
  value       = cloudflare_zero_trust_gateway_certificate.this
}

output "proxy_endpoint_ids" {
  description = "Map of proxy endpoint key to endpoint ID."
  value       = { for k, v in cloudflare_zero_trust_gateway_proxy_endpoint.this : k => v.id }
}

output "proxy_endpoint_subdomains" {
  description = "Map of proxy endpoint key to the assigned Cloudflare subdomain clients connect through."
  value       = { for k, v in cloudflare_zero_trust_gateway_proxy_endpoint.this : k => v.subdomain }
}

output "proxy_endpoints" {
  description = "Full proxy endpoint objects, keyed by the same keys as var.proxy_endpoints."
  value       = cloudflare_zero_trust_gateway_proxy_endpoint.this
}

output "dns_location_ids" {
  description = "Map of DNS location key to location ID."
  value       = { for k, v in cloudflare_zero_trust_dns_location.this : k => v.id }
}

output "dns_location_doh_subdomains" {
  description = "Map of DNS location key to its DNS over HTTPS subdomain."
  value       = { for k, v in cloudflare_zero_trust_dns_location.this : k => v.doh_subdomain }
}

output "dns_locations" {
  description = "Full DNS location objects, keyed by the same keys as var.dns_locations."
  value       = cloudflare_zero_trust_dns_location.this
}
