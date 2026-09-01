output "access_application_ids" {
  description = "Map of application key to application ID."
  value       = module.this.access_application_ids
}

output "access_application_auds" {
  description = "Map of application key to its audience tag."
  value       = module.this.access_application_auds
}

output "access_policy_ids" {
  description = "Map of policy key to policy ID."
  value       = module.this.access_policy_ids
}

output "access_group_ids" {
  description = "Map of group key to group ID."
  value       = module.this.access_group_ids
}

output "identity_provider_ids" {
  description = "Map of identity provider key to provider ID."
  value       = module.this.identity_provider_ids
}

output "service_token_client_ids" {
  description = "Map of service token key to client ID."
  value       = module.this.service_token_client_ids
}

output "service_token_client_secrets" {
  description = "Map of service token key to client secret."
  value       = module.this.service_token_client_secrets
  sensitive   = true
}

output "gateway_policy_ids" {
  description = "Map of Gateway policy key to policy ID."
  value       = module.this.gateway_policy_ids
}

output "tunnel_ids" {
  description = "Map of tunnel key to tunnel ID."
  value       = module.this.tunnel_ids
}

output "tunnel_cnames" {
  description = "Map of tunnel key to the CNAME target for a proxied DNS record."
  value       = module.this.tunnel_cnames
}

output "device_posture_rule_ids" {
  description = "Map of posture rule key to rule ID."
  value       = module.this.device_posture_rule_ids
}

output "dlp_profile_ids" {
  description = "Map of DLP profile key to profile ID."
  value       = module.this.dlp_profile_ids
}
