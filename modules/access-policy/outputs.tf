output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "access_tag_ids" {
  description = "Map of Access tag key to tag ID."
  value       = { for k, v in cloudflare_zero_trust_access_tag.this : k => v.id }
}

output "access_tags" {
  description = "Full Access tag objects, keyed by the same keys as var.access_tags."
  value       = cloudflare_zero_trust_access_tag.this
}

output "access_group_ids" {
  description = "Map of Access group key to group ID. Use these in a policy `group` selector."
  value       = { for k, v in cloudflare_zero_trust_access_group.this : k => v.id }
}

output "access_groups" {
  description = "Full Access group objects, keyed by the same keys as var.access_groups."
  value       = cloudflare_zero_trust_access_group.this
}

output "access_policy_ids" {
  description = "Map of Access policy key to policy ID. Feed these into an application's `policies` list."
  value       = { for k, v in cloudflare_zero_trust_access_policy.this : k => v.id }
}

output "access_policies" {
  description = "Full Access policy objects, keyed by the same keys as var.access_policies."
  value       = cloudflare_zero_trust_access_policy.this
}
