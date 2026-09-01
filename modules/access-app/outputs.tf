output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "application_ids" {
  description = "Map of application key to application ID."
  value       = { for k, v in cloudflare_zero_trust_access_application.this : k => v.id }
}

output "application_auds" {
  description = "Map of application key to the application audience (AUD) tag, used to validate Access JWTs."
  value       = { for k, v in cloudflare_zero_trust_access_application.this : k => v.aud }
}

output "application_domains" {
  description = "Map of application key to the primary domain the application protects."
  value       = { for k, v in cloudflare_zero_trust_access_application.this : k => v.domain }
}

output "applications" {
  description = "Full Access application objects, keyed by the same keys as var.applications."
  value       = cloudflare_zero_trust_access_application.this
  sensitive   = true
}

output "custom_page_ids" {
  description = "Map of custom page key to page ID."
  value       = { for k, v in cloudflare_zero_trust_access_custom_page.this : k => v.id }
}

output "custom_pages" {
  description = "Full Access custom page objects, keyed by the same keys as var.custom_pages."
  value       = cloudflare_zero_trust_access_custom_page.this
}
