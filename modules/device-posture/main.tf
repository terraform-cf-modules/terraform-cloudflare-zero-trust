# -----------------------------------------------------------------------------
# Submodule: device-posture
#
#   cloudflare_zero_trust_device_posture_rule         (v4: cloudflare_device_posture_rule)
#   cloudflare_zero_trust_device_posture_integration  (v4: cloudflare_device_posture_integration)
#   cloudflare_zero_trust_device_custom_profile       (v4: cloudflare_device_settings_policy)
#   cloudflare_zero_trust_device_default_profile      (v4: cloudflare_device_settings_policy, default = true)
#   cloudflare_zero_trust_device_managed_networks     (v4: cloudflare_device_managed_networks)
#   cloudflare_zero_trust_device_settings             (v4: cloudflare_device_settings)
#
# device_settings and default_profile are singletons per account. They are only
# created when the matching variable is non null.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  posture_rules        = local.enabled ? var.posture_rules : {}
  posture_integrations = local.enabled ? var.posture_integrations : {}
  managed_networks     = local.enabled ? var.managed_networks : {}
  custom_profiles      = local.enabled ? var.custom_profiles : {}

  manage_device_settings = local.enabled && var.device_settings != null
  manage_default_profile = local.enabled && var.default_profile != null
}

resource "cloudflare_zero_trust_device_posture_rule" "this" {
  for_each = local.posture_rules

  account_id  = var.account_id
  name        = coalesce(each.value.name, each.key)
  type        = each.value.type
  description = each.value.description
  expiration  = each.value.expiration
  schedule    = each.value.schedule
  match       = each.value.match
  input       = each.value.input
}

resource "cloudflare_zero_trust_device_posture_integration" "this" {
  for_each = local.posture_integrations

  account_id = var.account_id
  name       = coalesce(each.value.name, each.key)
  type       = each.value.type
  interval   = each.value.interval
  config     = each.value.config
}

resource "cloudflare_zero_trust_device_managed_networks" "this" {
  for_each = local.managed_networks

  account_id = var.account_id
  name       = coalesce(each.value.name, each.key)
  type       = each.value.type
  config     = each.value.config
}

resource "cloudflare_zero_trust_device_settings" "this" {
  count = local.manage_device_settings ? 1 : 0

  account_id                            = var.account_id
  disable_for_time                      = var.device_settings.disable_for_time
  gateway_proxy_enabled                 = var.device_settings.gateway_proxy_enabled
  gateway_udp_proxy_enabled             = var.device_settings.gateway_udp_proxy_enabled
  root_certificate_installation_enabled = var.device_settings.root_certificate_installation_enabled
  use_zt_virtual_ip                     = var.device_settings.use_zt_virtual_ip
  external_emergency_signal_enabled     = var.device_settings.external_emergency_signal_enabled
  external_emergency_signal_fingerprint = var.device_settings.external_emergency_signal_fingerprint
  external_emergency_signal_interval    = var.device_settings.external_emergency_signal_interval
  external_emergency_signal_url         = var.device_settings.external_emergency_signal_url
}

resource "cloudflare_zero_trust_device_default_profile" "this" {
  count = local.manage_default_profile ? 1 : 0

  account_id = var.account_id

  allow_mode_switch              = var.default_profile.allow_mode_switch
  allow_updates                  = var.default_profile.allow_updates
  allowed_to_leave               = var.default_profile.allowed_to_leave
  auto_connect                   = var.default_profile.auto_connect
  captive_portal                 = var.default_profile.captive_portal
  disable_auto_fallback          = var.default_profile.disable_auto_fallback
  exclude_office_ips             = var.default_profile.exclude_office_ips
  lan_allow_minutes              = var.default_profile.lan_allow_minutes
  lan_allow_subnet_size          = var.default_profile.lan_allow_subnet_size
  register_interface_ip_with_dns = var.default_profile.register_interface_ip_with_dns
  sccm_vpn_boundary_support      = var.default_profile.sccm_vpn_boundary_support
  support_url                    = var.default_profile.support_url
  switch_locked                  = var.default_profile.switch_locked
  tunnel_protocol                = var.default_profile.tunnel_protocol

  include             = var.default_profile.include
  exclude             = var.default_profile.exclude
  dns_search_suffixes = var.default_profile.dns_search_suffixes
  service_mode_v2     = var.default_profile.service_mode_v2
  virtual_networks    = var.default_profile.virtual_networks
  global_acceleration = var.default_profile.global_acceleration
}

resource "cloudflare_zero_trust_device_custom_profile" "this" {
  for_each = local.custom_profiles

  account_id  = var.account_id
  name        = coalesce(each.value.name, each.key)
  match       = each.value.match
  description = each.value.description
  enabled     = each.value.enabled
  precedence  = each.value.precedence

  allow_mode_switch              = each.value.allow_mode_switch
  allow_updates                  = each.value.allow_updates
  allowed_to_leave               = each.value.allowed_to_leave
  auto_connect                   = each.value.auto_connect
  captive_portal                 = each.value.captive_portal
  disable_auto_fallback          = each.value.disable_auto_fallback
  exclude_office_ips             = each.value.exclude_office_ips
  lan_allow_minutes              = each.value.lan_allow_minutes
  lan_allow_subnet_size          = each.value.lan_allow_subnet_size
  register_interface_ip_with_dns = each.value.register_interface_ip_with_dns
  sccm_vpn_boundary_support      = each.value.sccm_vpn_boundary_support
  support_url                    = each.value.support_url
  switch_locked                  = each.value.switch_locked
  tunnel_protocol                = each.value.tunnel_protocol

  include             = each.value.include
  exclude             = each.value.exclude
  dns_search_suffixes = each.value.dns_search_suffixes
  service_mode_v2     = each.value.service_mode_v2
  virtual_networks    = each.value.virtual_networks
  global_acceleration = each.value.global_acceleration
}
