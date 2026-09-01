# -----------------------------------------------------------------------------
# Submodule: gateway-policy
#
#   cloudflare_zero_trust_gateway_policy          (v4: cloudflare_teams_rule)
#   cloudflare_zero_trust_gateway_settings        (v4: cloudflare_teams_account)
#   cloudflare_zero_trust_gateway_certificate
#   cloudflare_zero_trust_gateway_proxy_endpoint  (v4: cloudflare_teams_proxy_endpoint)
#   cloudflare_zero_trust_gateway_logging
#   cloudflare_zero_trust_list                    (v4: cloudflare_teams_list)
#   cloudflare_zero_trust_dns_location            (v4: cloudflare_teams_location)
#
# Gateway settings and Gateway logging are singletons per account. They are
# created only when the matching variable is non null, so two callers do not
# silently fight over the same object.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  lists           = local.enabled ? var.lists : {}
  policies        = local.enabled ? var.policies : {}
  certificates    = local.enabled ? var.certificates : {}
  proxy_endpoints = local.enabled ? var.proxy_endpoints : {}
  dns_locations   = local.enabled ? var.dns_locations : {}

  manage_settings = local.enabled && var.settings != null
  manage_logging  = local.enabled && var.logging != null
}

resource "cloudflare_zero_trust_list" "this" {
  for_each = local.lists

  account_id  = var.account_id
  name        = coalesce(each.value.name, each.key)
  type        = each.value.type
  description = each.value.description
  items       = each.value.items
}

resource "cloudflare_zero_trust_gateway_policy" "this" {
  for_each = local.policies

  account_id     = var.account_id
  name           = coalesce(each.value.name, each.key)
  description    = each.value.description
  action         = each.value.action
  enabled        = each.value.enabled
  precedence     = each.value.precedence
  filters        = each.value.filters
  traffic        = each.value.traffic
  identity       = each.value.identity
  device_posture = each.value.device_posture

  expiration    = each.value.expiration
  schedule      = each.value.schedule
  rule_settings = each.value.rule_settings
}

resource "cloudflare_zero_trust_gateway_settings" "this" {
  count = local.manage_settings ? 1 : 0

  account_id = var.account_id
  settings   = var.settings
}

resource "cloudflare_zero_trust_gateway_logging" "this" {
  count = local.manage_logging ? 1 : 0

  account_id            = var.account_id
  redact_pii            = var.logging.redact_pii
  settings_by_rule_type = var.logging.settings_by_rule_type
}

resource "cloudflare_zero_trust_gateway_certificate" "this" {
  for_each = local.certificates

  account_id           = var.account_id
  validity_period_days = each.value.validity_period_days
  activate             = each.value.activate
}

resource "cloudflare_zero_trust_gateway_proxy_endpoint" "this" {
  for_each = local.proxy_endpoints

  account_id = var.account_id
  name       = coalesce(each.value.name, each.key)
  ips        = each.value.ips
  kind       = each.value.kind
}

resource "cloudflare_zero_trust_dns_location" "this" {
  for_each = local.dns_locations

  account_id             = var.account_id
  name                   = coalesce(each.value.name, each.key)
  client_default         = each.value.client_default
  ecs_support            = each.value.ecs_support
  dns_destination_ips_id = each.value.dns_destination_ips_id
  networks               = each.value.networks
  max_ttl                = each.value.max_ttl
  endpoints              = each.value.endpoints
}
