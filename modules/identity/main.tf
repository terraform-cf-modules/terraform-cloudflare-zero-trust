# -----------------------------------------------------------------------------
# Submodule: identity
#
#   cloudflare_zero_trust_access_identity_provider     (v4: cloudflare_access_identity_provider)
#   cloudflare_zero_trust_access_mtls_certificate      (v4: cloudflare_access_mutual_tls_certificate)
#   cloudflare_zero_trust_access_mtls_hostname_settings
#
# In v4 the identity provider config was a repeatable `config` block. In v5 it is
# a single flat object attribute, so it is written as config = { ... }.
#
# mtls_hostname_settings is a singleton per account or zone. The whole settings
# list is replaced on every apply, so it must contain every hostname you manage.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  identity_providers = local.enabled ? var.identity_providers : {}
  mtls_certificates  = local.enabled ? var.mtls_certificates : {}

  manage_mtls_hostname_settings = local.enabled && length(var.mtls_hostname_settings) > 0
}

resource "cloudflare_zero_trust_access_identity_provider" "this" {
  for_each = local.identity_providers

  account_id              = var.account_id
  zone_id                 = var.zone_id
  name                    = coalesce(each.value.name, each.key)
  type                    = each.value.type
  read_only               = each.value.read_only
  saml_certificate_set_id = each.value.saml_certificate_set_id
  config                  = each.value.config
  scim_config             = each.value.scim_config
}

resource "cloudflare_zero_trust_access_mtls_certificate" "this" {
  for_each = local.mtls_certificates

  account_id           = var.account_id
  zone_id              = var.zone_id
  name                 = coalesce(each.value.name, each.key)
  certificate          = each.value.certificate
  associated_hostnames = each.value.associated_hostnames
}

resource "cloudflare_zero_trust_access_mtls_hostname_settings" "this" {
  count = local.manage_mtls_hostname_settings ? 1 : 0

  account_id = var.account_id
  zone_id    = var.zone_id
  settings   = var.mtls_hostname_settings
}
