output "enabled" {
  description = "Whether this submodule created its resources."
  value       = local.enabled
}

output "profile_ids" {
  description = "Map of DLP profile key to profile ID. Reference these from a Gateway HTTP policy expression."
  value       = { for k, v in cloudflare_zero_trust_dlp_custom_profile.this : k => v.id }
}

output "profiles" {
  description = "Full DLP profile objects, keyed by the same keys as var.profiles."
  value       = cloudflare_zero_trust_dlp_custom_profile.this
}

output "entry_ids" {
  description = "Map of DLP entry key to entry ID."
  value       = { for k, v in cloudflare_zero_trust_dlp_custom_entry.this : k => v.id }
}

output "entries" {
  description = "Full DLP entry objects, keyed by the same keys as var.entries."
  value       = cloudflare_zero_trust_dlp_custom_entry.this
}

output "dataset_ids" {
  description = "Map of DLP dataset key to dataset ID."
  value       = { for k, v in cloudflare_zero_trust_dlp_dataset.this : k => v.id }
}

output "datasets" {
  description = "Full DLP dataset objects, keyed by the same keys as var.datasets."
  value       = cloudflare_zero_trust_dlp_dataset.this
}

output "settings" {
  description = "The account wide DLP settings object, or null when this module does not manage it."
  value       = one(cloudflare_zero_trust_dlp_settings.this)
}
