# -----------------------------------------------------------------------------
# Submodule: dlp
#
#   cloudflare_zero_trust_dlp_custom_profile  (v4: cloudflare_dlp_profile)
#   cloudflare_zero_trust_dlp_custom_entry
#   cloudflare_zero_trust_dlp_dataset         (v4: cloudflare_dlp_dataset)
#   cloudflare_zero_trust_dlp_settings
#
# A detection can live inline on a profile through `entries`, or as its own
# cloudflare_zero_trust_dlp_custom_entry resource attached with profile_id. Pick
# one per detection. Managing the same detection both ways makes the two
# resources fight on every apply.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  profiles = local.enabled ? var.profiles : {}
  entries  = local.enabled ? var.entries : {}
  datasets = local.enabled ? var.datasets : {}

  manage_settings = local.enabled && var.settings != null
}

resource "cloudflare_zero_trust_dlp_custom_profile" "this" {
  for_each = local.profiles

  account_id           = var.account_id
  name                 = coalesce(each.value.name, each.key)
  description          = each.value.description
  ai_context_enabled   = each.value.ai_context_enabled
  allowed_match_count  = each.value.allowed_match_count
  confidence_threshold = each.value.confidence_threshold
  ocr_enabled          = each.value.ocr_enabled
  data_classes         = each.value.data_classes
  data_tags            = each.value.data_tags

  # Left null when empty. The inline entries list is deprecated in provider 5.24
  # and setting it, even to an empty list, emits a sunset warning.
  entries            = length(each.value.entries) == 0 ? null : each.value.entries
  shared_entries     = length(each.value.shared_entries) == 0 ? null : each.value.shared_entries
  sensitivity_levels = each.value.sensitivity_levels
}

resource "cloudflare_zero_trust_dlp_custom_entry" "this" {
  for_each = local.entries

  account_id  = var.account_id
  name        = coalesce(each.value.name, each.key)
  enabled     = each.value.enabled
  description = each.value.description
  pattern     = each.value.pattern

  profile_id = (
    each.value.profile_key != null
    ? cloudflare_zero_trust_dlp_custom_profile.this[each.value.profile_key].id
    : each.value.profile_id
  )
}

resource "cloudflare_zero_trust_dlp_dataset" "this" {
  for_each = local.datasets

  account_id       = var.account_id
  name             = coalesce(each.value.name, each.key)
  description      = each.value.description
  case_sensitive   = each.value.case_sensitive
  encoding_version = each.value.encoding_version
  secret           = each.value.secret
  dataset_id       = each.value.dataset_id
}

resource "cloudflare_zero_trust_dlp_settings" "this" {
  count = local.manage_settings ? 1 : 0

  account_id          = var.account_id
  ai_context_analysis = var.settings.ai_context_analysis
  ocr                 = var.settings.ocr
  payload_logging     = var.settings.payload_logging
}
