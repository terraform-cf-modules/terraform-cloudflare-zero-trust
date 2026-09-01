# -----------------------------------------------------------------------------
# Submodule: access-policy
#
# Reusable Access policies, Access groups and Access tags.
#
#   cloudflare_zero_trust_access_policy  (v4 name: cloudflare_access_policy)
#   cloudflare_zero_trust_access_group   (v4 name: cloudflare_access_group)
#   cloudflare_zero_trust_access_tag
#
# In provider v5 a policy is a standalone, reusable object. It is no longer
# nested inside an application, and it no longer carries an application_id.
# Attach a policy to an application through the application's `policies` list.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  access_tags     = local.enabled ? var.access_tags : {}
  access_groups   = local.enabled ? var.access_groups : {}
  access_policies = local.enabled ? var.access_policies : {}
}

resource "cloudflare_zero_trust_access_tag" "this" {
  for_each = local.access_tags

  account_id = var.account_id
  name       = coalesce(each.value.name, each.key)
}

resource "cloudflare_zero_trust_access_group" "this" {
  for_each = local.access_groups

  account_id = var.account_id
  zone_id    = var.zone_id
  name       = coalesce(each.value.name, each.key)
  is_default = each.value.is_default

  include = each.value.include
  exclude = each.value.exclude
  require = each.value.require
}

resource "cloudflare_zero_trust_access_policy" "this" {
  for_each = local.access_policies

  account_id = var.account_id
  name       = coalesce(each.value.name, each.key)
  decision   = each.value.decision

  session_duration               = each.value.session_duration
  approval_required              = each.value.approval_required
  approval_groups                = each.value.approval_groups
  isolation_required             = each.value.isolation_required
  purpose_justification_required = each.value.purpose_justification_required
  purpose_justification_prompt   = each.value.purpose_justification_prompt
  mfa_config                     = each.value.mfa_config
  connection_rules               = each.value.connection_rules

  # Selectors written by the caller, plus any group created by this same module
  # instance and named through *_group_keys.
  include = concat(each.value.include, [
    for k in each.value.include_group_keys : { group = { id = cloudflare_zero_trust_access_group.this[k].id } }
  ])
  exclude = concat(coalesce(each.value.exclude, []), [
    for k in each.value.exclude_group_keys : { group = { id = cloudflare_zero_trust_access_group.this[k].id } }
  ])
  require = concat(coalesce(each.value.require, []), [
    for k in each.value.require_group_keys : { group = { id = cloudflare_zero_trust_access_group.this[k].id } }
  ])
}
