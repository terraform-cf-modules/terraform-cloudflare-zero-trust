output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "identity_provider_ids" {
  description = "Map of identity provider key to provider ID. Use these in an application's allowed_idps or in an Access policy selector."
  value       = { for k, v in cloudflare_zero_trust_access_identity_provider.this : k => v.id }
}

output "identity_providers" {
  description = "Full identity provider objects. Marked sensitive because config carries the OAuth client secret and scim_config carries the SCIM secret."
  value       = cloudflare_zero_trust_access_identity_provider.this
  sensitive   = true
}

output "identity_provider_scim_base_urls" {
  description = "Map of identity provider key to the SCIM base URL, empty when SCIM is not enabled."
  value       = { for k, v in cloudflare_zero_trust_access_identity_provider.this : k => try(v.scim_config.scim_base_url, null) }
}

output "mtls_certificate_ids" {
  description = "Map of mTLS certificate key to certificate ID."
  value       = { for k, v in cloudflare_zero_trust_access_mtls_certificate.this : k => v.id }
}

output "mtls_certificates" {
  description = "Full mTLS certificate objects, keyed by the same keys as var.mtls_certificates."
  value       = cloudflare_zero_trust_access_mtls_certificate.this
}

output "mtls_hostname_settings" {
  description = "The mTLS hostname settings object, or null when none are managed."
  value       = one(cloudflare_zero_trust_access_mtls_hostname_settings.this)
}
