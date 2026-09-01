output "access_application_ids" {
  description = "Map of application key to application ID."
  value       = module.this.access_application_ids
}

output "access_application_auds" {
  description = "Map of application key to its audience tag, used to validate Access JWTs at the origin."
  value       = module.this.access_application_auds
}

output "access_policy_ids" {
  description = "Map of policy key to policy ID."
  value       = module.this.access_policy_ids
}

output "identity_provider_ids" {
  description = "Map of identity provider key to provider ID."
  value       = module.this.identity_provider_ids
}
