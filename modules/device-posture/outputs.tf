output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "posture_rule_ids" {
  description = "Map of posture rule key to rule ID. Use these in a Gateway device_posture expression."
  value       = { for k, v in cloudflare_zero_trust_device_posture_rule.this : k => v.id }
}

output "posture_rules" {
  description = "Full posture rule objects, keyed by the same keys as var.posture_rules."
  value       = cloudflare_zero_trust_device_posture_rule.this
}

output "posture_integration_ids" {
  description = "Map of posture integration key to integration ID. Use these as integration_uid in an Access device_posture selector."
  value       = { for k, v in cloudflare_zero_trust_device_posture_integration.this : k => v.id }
}

output "posture_integrations" {
  description = "Full posture integration objects. Marked sensitive because config carries provider credentials."
  value       = cloudflare_zero_trust_device_posture_integration.this
  sensitive   = true
}

output "managed_network_ids" {
  description = "Map of managed network key to network ID."
  value       = { for k, v in cloudflare_zero_trust_device_managed_networks.this : k => v.id }
}

output "managed_networks" {
  description = "Full managed network objects, keyed by the same keys as var.managed_networks."
  value       = cloudflare_zero_trust_device_managed_networks.this
}

output "device_settings" {
  description = "The account wide device settings object, or null when this module does not manage it."
  value       = one(cloudflare_zero_trust_device_settings.this)
}

output "default_profile" {
  description = "The default WARP profile object, or null when this module does not manage it."
  value       = one(cloudflare_zero_trust_device_default_profile.this)
}

output "custom_profile_ids" {
  description = "Map of custom profile key to profile ID."
  value       = { for k, v in cloudflare_zero_trust_device_custom_profile.this : k => v.id }
}

output "custom_profiles" {
  description = "Full custom WARP profile objects, keyed by the same keys as var.custom_profiles."
  value       = cloudflare_zero_trust_device_custom_profile.this
}
