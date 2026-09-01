# -----------------------------------------------------------------------------
# Submodule: service-token
#
#   cloudflare_zero_trust_access_service_token            (v4: cloudflare_access_service_token)
#   cloudflare_zero_trust_access_short_lived_certificate   (v4: cloudflare_access_ca_certificate)
#
# client_secret is only returned by the API on creation. It is stored in state
# and every output that carries it is marked sensitive.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  service_tokens           = local.enabled ? var.service_tokens : {}
  short_lived_certificates = local.enabled ? var.short_lived_certificates : {}
}

resource "cloudflare_zero_trust_access_service_token" "this" {
  for_each = local.service_tokens

  account_id = var.account_id
  zone_id    = var.zone_id
  name       = coalesce(each.value.name, each.key)
  duration   = each.value.duration
  enabled    = each.value.enabled

  client_secret_version             = each.value.client_secret_version
  previous_client_secret_expires_at = each.value.previous_client_secret_expires_at
}

resource "cloudflare_zero_trust_access_short_lived_certificate" "this" {
  for_each = local.short_lived_certificates

  account_id = var.account_id
  zone_id    = var.zone_id
  app_id     = each.value.app_id
}
