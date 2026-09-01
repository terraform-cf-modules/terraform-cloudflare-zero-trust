locals {
  # Single switch consulted by every submodule in this module.
  enabled = var.enabled

  # ---------------------------------------------------------------------------
  # Access policies, with the root module conveniences resolved to real IDs.
  #
  # include_service_token_keys and include_login_method_idp_keys let a caller
  # name a service token or identity provider created by this same module
  # instead of hard coding an ID that does not exist until after the first apply.
  # ---------------------------------------------------------------------------
  access_policies = {
    for k, p in var.access_policies : k => {
      name                           = p.name
      decision                       = p.decision
      session_duration               = p.session_duration
      approval_required              = p.approval_required
      isolation_required             = p.isolation_required
      purpose_justification_required = p.purpose_justification_required
      purpose_justification_prompt   = p.purpose_justification_prompt
      approval_groups                = p.approval_groups
      mfa_config                     = p.mfa_config
      connection_rules               = p.connection_rules
      include_group_keys             = p.include_group_keys
      exclude_group_keys             = p.exclude_group_keys
      require_group_keys             = p.require_group_keys
      exclude                        = p.exclude
      require                        = p.require

      include = concat(
        p.include,
        [for tk in p.include_service_token_keys : {
          service_token = { token_id = module.service_token.service_token_ids[tk] }
        }],
        [for ik in p.include_login_method_idp_keys : {
          login_method = { id = module.identity.identity_provider_ids[ik] }
        }],
      )
    }
  }

  # ---------------------------------------------------------------------------
  # Access applications, with policy_keys and allowed_idp_keys resolved.
  # ---------------------------------------------------------------------------
  access_applications = {
    for k, a in var.access_applications : k => {
      name                            = a.name
      type                            = a.type
      domain                          = a.domain
      session_duration                = a.session_duration
      tags                            = a.tags
      custom_pages                    = a.custom_pages
      custom_page_keys                = a.custom_page_keys
      auto_redirect_to_identity       = a.auto_redirect_to_identity
      app_launcher_visible            = a.app_launcher_visible
      app_launcher_logo_url           = a.app_launcher_logo_url
      bg_color                        = a.bg_color
      header_bg_color                 = a.header_bg_color
      logo_url                        = a.logo_url
      custom_deny_message             = a.custom_deny_message
      custom_deny_url                 = a.custom_deny_url
      custom_non_identity_deny_url    = a.custom_non_identity_deny_url
      enable_binding_cookie           = a.enable_binding_cookie
      http_only_cookie_attribute      = a.http_only_cookie_attribute
      path_cookie_attribute           = a.path_cookie_attribute
      same_site_cookie_attribute      = a.same_site_cookie_attribute
      options_preflight_bypass        = a.options_preflight_bypass
      service_auth_401_redirect       = a.service_auth_401_redirect
      skip_interstitial               = a.skip_interstitial
      skip_app_launcher_login_page    = a.skip_app_launcher_login_page
      allow_authenticate_via_warp     = a.allow_authenticate_via_warp
      allow_iframe                    = a.allow_iframe
      read_service_tokens_from_header = a.read_service_tokens_from_header
      cors_headers                    = a.cors_headers
      destinations                    = a.destinations
      footer_links                    = a.footer_links
      landing_page_design             = a.landing_page_design
      mfa_config                      = a.mfa_config
      oauth_configuration             = a.oauth_configuration
      target_criteria                 = a.target_criteria
      scim_config                     = a.scim_config
      saas_app                        = a.saas_app

      policies = concat(
        a.policies,
        [for pk in a.policy_keys : {
          id         = module.access_policy.access_policy_ids[pk]
          precedence = null
        }],
      )

      allowed_idps = (
        length(coalesce(a.allowed_idps, toset([]))) + length(a.allowed_idp_keys) == 0
        ? null
        : toset(concat(
          tolist(coalesce(a.allowed_idps, toset([]))),
          [for ik in a.allowed_idp_keys : module.identity.identity_provider_ids[ik]],
        ))
      )
    }
  }

  # ---------------------------------------------------------------------------
  # Short lived certificates, with app_key resolved to an application ID.
  # ---------------------------------------------------------------------------
  short_lived_certificates = {
    for k, c in var.short_lived_certificates : k => {
      app_id = c.app_key != null ? module.access_app.application_ids[c.app_key] : c.app_id
    }
  }
}
