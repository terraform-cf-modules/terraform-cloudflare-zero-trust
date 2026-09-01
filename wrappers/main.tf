# -----------------------------------------------------------------------------
# Wrapper: create many instances of the root module from a single map.
#
#   module "zero_trust" {
#     source = "terraform-cf-modules/zero-trust/cloudflare//wrappers"
#
#     defaults = {
#       account_id = var.account_id
#     }
#
#     items = {
#       corp = {
#         access_applications = { intranet = { domain = "intranet.example.com" } }
#       }
#       lab = {
#         enabled = false
#       }
#     }
#   }
# -----------------------------------------------------------------------------

module "wrapper" {
  source = "../"

  for_each = var.items

  enabled    = try(each.value.enabled, var.defaults.enabled, true)
  account_id = try(each.value.account_id, var.defaults.account_id, null)
  zone_id    = try(each.value.zone_id, var.defaults.zone_id, null)

  # Identity
  identity_providers     = try(each.value.identity_providers, var.defaults.identity_providers, {})
  mtls_certificates      = try(each.value.mtls_certificates, var.defaults.mtls_certificates, {})
  mtls_hostname_settings = try(each.value.mtls_hostname_settings, var.defaults.mtls_hostname_settings, [])

  # Service tokens
  service_tokens           = try(each.value.service_tokens, var.defaults.service_tokens, {})
  short_lived_certificates = try(each.value.short_lived_certificates, var.defaults.short_lived_certificates, {})

  # Access
  access_tags         = try(each.value.access_tags, var.defaults.access_tags, {})
  access_groups       = try(each.value.access_groups, var.defaults.access_groups, {})
  access_policies     = try(each.value.access_policies, var.defaults.access_policies, {})
  access_applications = try(each.value.access_applications, var.defaults.access_applications, {})
  access_custom_pages = try(each.value.access_custom_pages, var.defaults.access_custom_pages, {})

  # Gateway
  gateway_lists           = try(each.value.gateway_lists, var.defaults.gateway_lists, {})
  gateway_policies        = try(each.value.gateway_policies, var.defaults.gateway_policies, {})
  gateway_settings        = try(each.value.gateway_settings, var.defaults.gateway_settings, null)
  gateway_logging         = try(each.value.gateway_logging, var.defaults.gateway_logging, null)
  gateway_certificates    = try(each.value.gateway_certificates, var.defaults.gateway_certificates, {})
  gateway_proxy_endpoints = try(each.value.gateway_proxy_endpoints, var.defaults.gateway_proxy_endpoints, {})
  dns_locations           = try(each.value.dns_locations, var.defaults.dns_locations, {})

  # Tunnels
  tunnels                 = try(each.value.tunnels, var.defaults.tunnels, {})
  tunnel_virtual_networks = try(each.value.tunnel_virtual_networks, var.defaults.tunnel_virtual_networks, {})
  tunnel_routes           = try(each.value.tunnel_routes, var.defaults.tunnel_routes, {})

  # Device posture
  device_posture_rules        = try(each.value.device_posture_rules, var.defaults.device_posture_rules, {})
  device_posture_integrations = try(each.value.device_posture_integrations, var.defaults.device_posture_integrations, {})
  device_managed_networks     = try(each.value.device_managed_networks, var.defaults.device_managed_networks, {})
  device_settings             = try(each.value.device_settings, var.defaults.device_settings, null)
  device_default_profile      = try(each.value.device_default_profile, var.defaults.device_default_profile, null)
  device_custom_profiles      = try(each.value.device_custom_profiles, var.defaults.device_custom_profiles, {})

  # DLP
  dlp_profiles = try(each.value.dlp_profiles, var.defaults.dlp_profiles, {})
  dlp_entries  = try(each.value.dlp_entries, var.defaults.dlp_entries, {})
  dlp_datasets = try(each.value.dlp_datasets, var.defaults.dlp_datasets, {})
  dlp_settings = try(each.value.dlp_settings, var.defaults.dlp_settings, null)
}
