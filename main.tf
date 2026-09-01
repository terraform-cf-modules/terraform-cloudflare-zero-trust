# -----------------------------------------------------------------------------
# Module: Cloudflare Zero Trust
# Access applications and policies, Gateway policies, Cloudflared tunnels,
# device posture, and DLP.
#
# The root module composes the building blocks under modules/ into one working
# Zero Trust posture: an identity provider, reusable Access groups and policies,
# the applications those policies protect, service tokens for machine callers,
# Gateway rules, Cloudflared tunnels, device posture and DLP.
#
# Each building block is also publishable on its own:
#
#   source = "terraform-cf-modules/zero-trust/cloudflare//modules/<name>"
#
# Wiring notes
#   * service-token is called twice. Tokens must exist before Access policies
#     can reference them, and short lived certificates need an application ID,
#     so splitting the two avoids a module level dependency cycle.
#   * Cross references between submodules are made by key, not by ID, so a
#     caller never has to know an ID that does not exist until after apply.
# -----------------------------------------------------------------------------

module "identity" {
  source = "./modules/identity"

  enabled    = local.enabled
  account_id = var.account_id
  zone_id    = var.zone_id

  identity_providers     = var.identity_providers
  mtls_certificates      = var.mtls_certificates
  mtls_hostname_settings = var.mtls_hostname_settings
}

module "service_token" {
  source = "./modules/service-token"

  enabled    = local.enabled
  account_id = var.account_id
  zone_id    = var.zone_id

  service_tokens = var.service_tokens

  # Short lived certificates are created by the second instance below, once the
  # applications they sign for exist.
  short_lived_certificates = {}
}

module "access_policy" {
  source = "./modules/access-policy"

  enabled    = local.enabled
  account_id = var.account_id
  zone_id    = var.zone_id

  access_tags     = var.access_tags
  access_groups   = var.access_groups
  access_policies = local.access_policies
}

module "access_app" {
  source = "./modules/access-app"

  enabled    = local.enabled
  account_id = var.account_id
  zone_id    = var.zone_id

  applications = local.access_applications
  custom_pages = var.access_custom_pages
}

module "short_lived_certificate" {
  source = "./modules/service-token"

  enabled    = local.enabled
  account_id = var.account_id
  zone_id    = var.zone_id

  service_tokens           = {}
  short_lived_certificates = local.short_lived_certificates
}

module "gateway_policy" {
  source = "./modules/gateway-policy"

  enabled    = local.enabled
  account_id = var.account_id

  lists           = var.gateway_lists
  policies        = var.gateway_policies
  settings        = var.gateway_settings
  logging         = var.gateway_logging
  certificates    = var.gateway_certificates
  proxy_endpoints = var.gateway_proxy_endpoints
  dns_locations   = var.dns_locations
}

module "tunnel" {
  source = "./modules/tunnel"

  enabled    = local.enabled
  account_id = var.account_id

  tunnels          = var.tunnels
  virtual_networks = var.tunnel_virtual_networks
  routes           = var.tunnel_routes
}

module "device_posture" {
  source = "./modules/device-posture"

  enabled    = local.enabled
  account_id = var.account_id

  posture_rules        = var.device_posture_rules
  posture_integrations = var.device_posture_integrations
  managed_networks     = var.device_managed_networks
  device_settings      = var.device_settings
  default_profile      = var.device_default_profile
  custom_profiles      = var.device_custom_profiles
}

module "dlp" {
  source = "./modules/dlp"

  enabled    = local.enabled
  account_id = var.account_id

  profiles = var.dlp_profiles
  entries  = var.dlp_entries
  datasets = var.dlp_datasets
  settings = var.dlp_settings
}
