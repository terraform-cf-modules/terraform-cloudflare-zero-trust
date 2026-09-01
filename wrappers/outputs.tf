output "wrapper" {
  description = "Map of module outputs, keyed by the same keys as var.items. Sensitive because the root module exposes tunnel secrets and service token client secrets."
  value       = module.wrapper
  sensitive   = true
}
