# -----------------------------------------------------------------------------
# Submodule: access-app
#
#   cloudflare_zero_trust_access_application  (v4 name: cloudflare_access_application)
#   cloudflare_zero_trust_access_custom_page
#
# An application is protected by attaching reusable policies through the
# `policies` list. Create those with the access-policy submodule.
#
# Provider quirks encoded here:
#   * `self_hosted_domains` is deprecated in v5. Use `destinations` instead.
#   * `saas_app` is rejected unless type is saas or dash_sso.
#   * `footer_links` and `landing_page_design` are rejected unless type is app_launcher.
#   * `cors_headers` needs exactly one of allow_all_origins or allowed_origins.
# -----------------------------------------------------------------------------

locals {
  enabled      = var.enabled
  applications = local.enabled ? var.applications : {}
  custom_pages = local.enabled ? var.custom_pages : {}
}

resource "cloudflare_zero_trust_access_custom_page" "this" {
  for_each = local.custom_pages

  account_id       = var.account_id
  name             = coalesce(each.value.name, each.key)
  type             = each.value.type
  custom_html      = each.value.custom_html
  contract_version = each.value.contract_version
}

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = local.applications

  account_id = var.account_id
  zone_id    = var.zone_id

  name             = coalesce(each.value.name, each.key)
  type             = each.value.type
  domain           = each.value.domain
  session_duration = each.value.session_duration
  allowed_idps     = each.value.allowed_idps
  tags             = each.value.tags
  custom_pages = length(coalesce(each.value.custom_pages, [])) + length(each.value.custom_page_keys) == 0 ? null : concat(
    coalesce(each.value.custom_pages, []),
    [for k in each.value.custom_page_keys : cloudflare_zero_trust_access_custom_page.this[k].id],
  )

  auto_redirect_to_identity       = each.value.auto_redirect_to_identity
  app_launcher_visible            = each.value.app_launcher_visible
  app_launcher_logo_url           = each.value.app_launcher_logo_url
  bg_color                        = each.value.bg_color
  header_bg_color                 = each.value.header_bg_color
  logo_url                        = each.value.logo_url
  custom_deny_message             = each.value.custom_deny_message
  custom_deny_url                 = each.value.custom_deny_url
  custom_non_identity_deny_url    = each.value.custom_non_identity_deny_url
  enable_binding_cookie           = each.value.enable_binding_cookie
  http_only_cookie_attribute      = each.value.http_only_cookie_attribute
  path_cookie_attribute           = each.value.path_cookie_attribute
  same_site_cookie_attribute      = each.value.same_site_cookie_attribute
  options_preflight_bypass        = each.value.options_preflight_bypass
  service_auth_401_redirect       = each.value.service_auth_401_redirect
  skip_interstitial               = each.value.skip_interstitial
  skip_app_launcher_login_page    = each.value.skip_app_launcher_login_page
  allow_authenticate_via_warp     = each.value.allow_authenticate_via_warp
  allow_iframe                    = each.value.allow_iframe
  read_service_tokens_from_header = each.value.read_service_tokens_from_header

  policies            = each.value.policies
  cors_headers        = each.value.cors_headers
  destinations        = each.value.destinations
  footer_links        = each.value.footer_links
  landing_page_design = each.value.landing_page_design
  mfa_config          = each.value.mfa_config
  oauth_configuration = each.value.oauth_configuration
  target_criteria     = each.value.target_criteria
  scim_config         = each.value.scim_config
  saas_app            = each.value.saas_app
}
