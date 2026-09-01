output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "service_token_ids" {
  description = "Map of service token key to token ID. Use these in an Access policy service_token selector."
  value       = { for k, v in cloudflare_zero_trust_access_service_token.this : k => v.id }
}

output "service_token_client_ids" {
  description = "Map of service token key to client ID. Sent as the CF-Access-Client-Id header."
  value       = { for k, v in cloudflare_zero_trust_access_service_token.this : k => v.client_id }
}

output "service_token_client_secrets" {
  description = "Map of service token key to client secret. Sent as the CF-Access-Client-Secret header. Returned by the API on creation only."
  value       = { for k, v in cloudflare_zero_trust_access_service_token.this : k => v.client_secret }
  sensitive   = true
}

output "service_token_expires_at" {
  description = "Map of service token key to expiry timestamp."
  value       = { for k, v in cloudflare_zero_trust_access_service_token.this : k => v.expires_at }
}

output "service_tokens" {
  description = "Full service token objects. Marked sensitive because each carries client_secret."
  value       = cloudflare_zero_trust_access_service_token.this
  sensitive   = true
}

output "short_lived_certificate_ids" {
  description = "Map of short lived certificate key to certificate ID."
  value       = { for k, v in cloudflare_zero_trust_access_short_lived_certificate.this : k => v.id }
}

output "short_lived_certificate_public_keys" {
  description = "Map of short lived certificate key to the SSH CA public key. Install this on the target hosts as a TrustedUserCAKeys entry."
  value       = { for k, v in cloudflare_zero_trust_access_short_lived_certificate.this : k => v.public_key }
}

output "short_lived_certificates" {
  description = "Full short lived certificate objects, keyed by the same keys as var.short_lived_certificates."
  value       = cloudflare_zero_trust_access_short_lived_certificate.this
}
