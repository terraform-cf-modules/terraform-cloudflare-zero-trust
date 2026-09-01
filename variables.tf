# -----------------------------------------------------------------------------
# Common inputs. Every module in this organisation exposes these.
# -----------------------------------------------------------------------------

variable "enabled" {
  description = "Whether to create the resources managed by this module. Set to false to disable the module without removing the block."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the resources. Required for account scoped resources, which is almost everything in Zero Trust."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID, used only by the zone scoped Access resources: applications, groups, identity providers, mTLS certificates and service tokens."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

# -----------------------------------------------------------------------------
# Identity: providers and mutual TLS
# Passed through to modules/identity.
# -----------------------------------------------------------------------------

variable "identity_providers" {
  description = <<-EOT
    Access identity providers, keyed by a stable identifier.

    `config` is a single flat object in provider v5. Which fields matter depends on `type`: OIDC style providers
    use client_id, client_secret, auth_url, token_url, certs_url and scopes, SAML uses issuer_url, sso_target_url,
    idp_public_certs and attributes, and `onetimepin` needs an empty config object.

    Provider secrets are written into Terraform state. Supply them from a secret store, never as a literal.
  EOT
  type = map(object({
    name                    = optional(string)
    type                    = string
    read_only               = optional(bool)
    saml_certificate_set_id = optional(string)

    config = object({
      apps_domain                 = optional(string)
      attributes                  = optional(list(string))
      auth_url                    = optional(string)
      authorization_server_id     = optional(string)
      centrify_account            = optional(string)
      centrify_app_id             = optional(string)
      certs_url                   = optional(string)
      claims                      = optional(list(string))
      client_id                   = optional(string)
      client_secret               = optional(string)
      conditional_access_enabled  = optional(bool)
      directory_id                = optional(string)
      email_attribute_name        = optional(string)
      email_claim_name            = optional(string)
      enable_encryption           = optional(bool)
      idp_public_certs            = optional(list(string))
      issuer_url                  = optional(string)
      okta_account                = optional(string)
      onelogin_account            = optional(string)
      ping_env_id                 = optional(string)
      pkce_enabled                = optional(bool)
      prompt                      = optional(string)
      restrict_to_account_members = optional(bool)
      scopes                      = optional(list(string))
      sign_request                = optional(bool)
      sso_target_url              = optional(string)
      support_groups              = optional(bool)
      token_url                   = optional(string)
      header_attributes = optional(list(object({
        attribute_name = optional(string)
        header_name    = optional(string)
      })))
    })

    scim_config = optional(object({
      enabled                  = optional(bool)
      identity_update_behavior = optional(string)
      seat_deprovision         = optional(bool)
      user_deprovision         = optional(bool)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for i in values(var.identity_providers) :
      contains([
        "onetimepin", "azureAD", "saml", "centrify", "facebook", "github", "google-apps",
        "google", "linkedin", "oidc", "okta", "onelogin", "pingone", "yandex", "cloudflare",
      ], i.type)
    ])
    error_message = "Each identity provider type must be one of onetimepin, azureAD, saml, centrify, facebook, github, google-apps, google, linkedin, oidc, okta, onelogin, pingone, yandex, cloudflare."
  }

  validation {
    condition = alltrue([
      for i in values(var.identity_providers) :
      i.config.prompt == null || contains(["login", "select_account", "none"], i.config.prompt)
    ])
    error_message = "identity provider config.prompt must be one of login, select_account, none."
  }

  validation {
    condition = alltrue([
      for i in values(var.identity_providers) :
      try(i.scim_config.identity_update_behavior, null) == null ||
      contains(["automatic", "reauth", "no_action"], i.scim_config.identity_update_behavior)
    ])
    error_message = "scim_config.identity_update_behavior must be one of automatic, reauth, no_action."
  }
}

variable "mtls_certificates" {
  description = "Access mTLS root certificates, keyed by a stable identifier. `certificate` is the PEM encoded CA certificate."
  type = map(object({
    name                 = optional(string)
    certificate          = string
    associated_hostnames = optional(set(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for c in values(var.mtls_certificates) :
      can(regex("BEGIN CERTIFICATE", c.certificate))
    ])
    error_message = "Each mTLS certificate must be a PEM encoded certificate containing a BEGIN CERTIFICATE header."
  }
}

variable "mtls_hostname_settings" {
  description = "Per hostname mTLS behaviour. The Cloudflare API models this as one settings object per scope, so this is a list rather than a map. Leave empty to manage nothing."
  type = list(object({
    hostname                      = string
    china_network                 = bool
    client_certificate_forwarding = bool
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Service tokens and short lived certificates
# Passed through to modules/service-token.
# -----------------------------------------------------------------------------

variable "service_tokens" {
  description = <<-EOT
    Access service tokens for machine to machine authentication, keyed by a stable identifier.

    `duration` is the token lifetime, for example `8760h`. Bump `client_secret_version` to rotate the secret;
    `previous_client_secret_expires_at` sets how long the old secret keeps working during the rotation.
  EOT
  type = map(object({
    name                              = optional(string)
    duration                          = optional(string)
    enabled                           = optional(bool)
    client_secret_version             = optional(number)
    previous_client_secret_expires_at = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in values(var.service_tokens) :
      t.duration == null || can(regex("^([0-9]+(ns|us|µs|ms|s|m|h))+$", t.duration))
    ])
    error_message = "service token duration must look like 8760h. Valid units are ns, us, µs, ms, s, m, h."
  }
}

variable "short_lived_certificates" {
  description = "Short lived certificate (SSH CA) issuers, keyed by a stable identifier. Set `app_key` to name an application created by this module, or `app_id` to point at an existing one."
  type = map(object({
    app_key = optional(string)
    app_id  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for c in values(var.short_lived_certificates) :
      (c.app_key == null) != (c.app_id == null)
    ])
    error_message = "Each short lived certificate must set exactly one of app_key or app_id."
  }

  validation {
    condition = alltrue([
      for c in values(var.short_lived_certificates) :
      c.app_key == null || contains(keys(var.access_applications), c.app_key)
    ])
    error_message = "Every short lived certificate app_key must name a key in var.access_applications."
  }
}

# -----------------------------------------------------------------------------
# Access groups, policies and tags
# Passed through to modules/access-policy.
# -----------------------------------------------------------------------------

variable "access_tags" {
  description = "Access tags to create, keyed by a stable identifier. Tags group applications in the Zero Trust dashboard."
  type = map(object({
    name = optional(string)
  }))
  default = {}
}

variable "access_groups" {
  description = "Reusable Access groups, keyed by a stable identifier. `include` must contain at least one selector."
  type = map(object({
    name       = optional(string)
    is_default = optional(bool)
    include = list(object({
      any_valid_service_token   = optional(object({}))
      auth_context              = optional(object({ ac_id = string, id = string, identity_provider_id = string }))
      auth_method               = optional(object({ auth_method = string }))
      azure_ad                  = optional(object({ id = string, identity_provider_id = string }))
      certificate               = optional(object({}))
      cloudflare_account_member = optional(object({ account_id = optional(string) }))
      common_name               = optional(object({ common_name = string }))
      device_posture            = optional(object({ integration_uid = string }))
      email                     = optional(object({ email = string }))
      email_domain              = optional(object({ domain = string }))
      email_list                = optional(object({ id = string }))
      everyone                  = optional(object({}))
      external_evaluation       = optional(object({ evaluate_url = string, keys_url = string }))
      geo                       = optional(object({ country_code = string }))
      github_organization       = optional(object({ identity_provider_id = string, name = string, team = optional(string) }))
      group                     = optional(object({ id = string }))
      gsuite                    = optional(object({ email = string, identity_provider_id = string }))
      ip                        = optional(object({ ip = string }))
      ip_list                   = optional(object({ id = string }))
      linked_app_token          = optional(object({ app_uid = string }))
      login_method              = optional(object({ id = string }))
      oidc                      = optional(object({ claim_name = string, claim_value = string, identity_provider_id = string }))
      okta                      = optional(object({ identity_provider_id = string, name = string }))
      saml                      = optional(object({ attribute_name = string, attribute_value = string, identity_provider_id = string }))
      service_token             = optional(object({ token_id = string }))
      user_risk_score           = optional(object({ user_risk_score = list(string) }))
    }))
    exclude = optional(list(object({
      any_valid_service_token   = optional(object({}))
      auth_context              = optional(object({ ac_id = string, id = string, identity_provider_id = string }))
      auth_method               = optional(object({ auth_method = string }))
      azure_ad                  = optional(object({ id = string, identity_provider_id = string }))
      certificate               = optional(object({}))
      cloudflare_account_member = optional(object({ account_id = optional(string) }))
      common_name               = optional(object({ common_name = string }))
      device_posture            = optional(object({ integration_uid = string }))
      email                     = optional(object({ email = string }))
      email_domain              = optional(object({ domain = string }))
      email_list                = optional(object({ id = string }))
      everyone                  = optional(object({}))
      external_evaluation       = optional(object({ evaluate_url = string, keys_url = string }))
      geo                       = optional(object({ country_code = string }))
      github_organization       = optional(object({ identity_provider_id = string, name = string, team = optional(string) }))
      group                     = optional(object({ id = string }))
      gsuite                    = optional(object({ email = string, identity_provider_id = string }))
      ip                        = optional(object({ ip = string }))
      ip_list                   = optional(object({ id = string }))
      linked_app_token          = optional(object({ app_uid = string }))
      login_method              = optional(object({ id = string }))
      oidc                      = optional(object({ claim_name = string, claim_value = string, identity_provider_id = string }))
      okta                      = optional(object({ identity_provider_id = string, name = string }))
      saml                      = optional(object({ attribute_name = string, attribute_value = string, identity_provider_id = string }))
      service_token             = optional(object({ token_id = string }))
      user_risk_score           = optional(object({ user_risk_score = list(string) }))
    })))
    require = optional(list(object({
      any_valid_service_token   = optional(object({}))
      auth_context              = optional(object({ ac_id = string, id = string, identity_provider_id = string }))
      auth_method               = optional(object({ auth_method = string }))
      azure_ad                  = optional(object({ id = string, identity_provider_id = string }))
      certificate               = optional(object({}))
      cloudflare_account_member = optional(object({ account_id = optional(string) }))
      common_name               = optional(object({ common_name = string }))
      device_posture            = optional(object({ integration_uid = string }))
      email                     = optional(object({ email = string }))
      email_domain              = optional(object({ domain = string }))
      email_list                = optional(object({ id = string }))
      everyone                  = optional(object({}))
      external_evaluation       = optional(object({ evaluate_url = string, keys_url = string }))
      geo                       = optional(object({ country_code = string }))
      github_organization       = optional(object({ identity_provider_id = string, name = string, team = optional(string) }))
      group                     = optional(object({ id = string }))
      gsuite                    = optional(object({ email = string, identity_provider_id = string }))
      ip                        = optional(object({ ip = string }))
      ip_list                   = optional(object({ id = string }))
      linked_app_token          = optional(object({ app_uid = string }))
      login_method              = optional(object({ id = string }))
      oidc                      = optional(object({ claim_name = string, claim_value = string, identity_provider_id = string }))
      okta                      = optional(object({ identity_provider_id = string, name = string }))
      saml                      = optional(object({ attribute_name = string, attribute_value = string, identity_provider_id = string }))
      service_token             = optional(object({ token_id = string }))
      user_risk_score           = optional(object({ user_risk_score = list(string) }))
    })))
  }))
  default = {}

  validation {
    condition     = alltrue([for g in values(var.access_groups) : length(g.include) > 0])
    error_message = "Each Access group must have at least one include selector."
  }
}

variable "access_policies" {
  description = "Reusable Access policies, keyed by a stable identifier. Attach them to applications with the access-app submodule."
  type = map(object({
    name     = optional(string)
    decision = string

    # Keys of entries in var.access_groups. Each one is appended to the matching
    # rule list as a { group = { id = ... } } selector, so a policy can reference
    # a group created by this same module instance without a module level cycle.
    include_group_keys = optional(list(string), [])
    exclude_group_keys = optional(list(string), [])
    require_group_keys = optional(list(string), [])

    # Root module conveniences. Keys of entries in var.service_tokens and
    # var.identity_providers, resolved to IDs and appended to `include`.
    include_service_token_keys    = optional(list(string), [])
    include_login_method_idp_keys = optional(list(string), [])

    session_duration               = optional(string)
    approval_required              = optional(bool)
    isolation_required             = optional(bool)
    purpose_justification_required = optional(bool)
    purpose_justification_prompt   = optional(string)
    approval_groups = optional(list(object({
      approvals_needed = number
      email_addresses  = optional(list(string))
      email_list_uuid  = optional(string)
    })))
    mfa_config = optional(object({
      allowed_authenticators = optional(list(string))
      mfa_disabled           = optional(bool)
      session_duration       = optional(string)
    }))
    connection_rules = optional(object({
      rdp = optional(object({
        allowed_clipboard_local_to_remote_formats = optional(list(string))
        allowed_clipboard_remote_to_local_formats = optional(list(string))
      }))
    }))
    include = list(object({
      any_valid_service_token   = optional(object({}))
      auth_context              = optional(object({ ac_id = string, id = string, identity_provider_id = string }))
      auth_method               = optional(object({ auth_method = string }))
      azure_ad                  = optional(object({ id = string, identity_provider_id = string }))
      certificate               = optional(object({}))
      cloudflare_account_member = optional(object({ account_id = optional(string) }))
      common_name               = optional(object({ common_name = string }))
      device_posture            = optional(object({ integration_uid = string }))
      email                     = optional(object({ email = string }))
      email_domain              = optional(object({ domain = string }))
      email_list                = optional(object({ id = string }))
      everyone                  = optional(object({}))
      external_evaluation       = optional(object({ evaluate_url = string, keys_url = string }))
      geo                       = optional(object({ country_code = string }))
      github_organization       = optional(object({ identity_provider_id = string, name = string, team = optional(string) }))
      group                     = optional(object({ id = string }))
      gsuite                    = optional(object({ email = string, identity_provider_id = string }))
      ip                        = optional(object({ ip = string }))
      ip_list                   = optional(object({ id = string }))
      linked_app_token          = optional(object({ app_uid = string }))
      login_method              = optional(object({ id = string }))
      oidc                      = optional(object({ claim_name = string, claim_value = string, identity_provider_id = string }))
      okta                      = optional(object({ identity_provider_id = string, name = string }))
      saml                      = optional(object({ attribute_name = string, attribute_value = string, identity_provider_id = string }))
      service_token             = optional(object({ token_id = string }))
      user_risk_score           = optional(object({ user_risk_score = list(string) }))
    }))
    exclude = optional(list(object({
      any_valid_service_token   = optional(object({}))
      auth_context              = optional(object({ ac_id = string, id = string, identity_provider_id = string }))
      auth_method               = optional(object({ auth_method = string }))
      azure_ad                  = optional(object({ id = string, identity_provider_id = string }))
      certificate               = optional(object({}))
      cloudflare_account_member = optional(object({ account_id = optional(string) }))
      common_name               = optional(object({ common_name = string }))
      device_posture            = optional(object({ integration_uid = string }))
      email                     = optional(object({ email = string }))
      email_domain              = optional(object({ domain = string }))
      email_list                = optional(object({ id = string }))
      everyone                  = optional(object({}))
      external_evaluation       = optional(object({ evaluate_url = string, keys_url = string }))
      geo                       = optional(object({ country_code = string }))
      github_organization       = optional(object({ identity_provider_id = string, name = string, team = optional(string) }))
      group                     = optional(object({ id = string }))
      gsuite                    = optional(object({ email = string, identity_provider_id = string }))
      ip                        = optional(object({ ip = string }))
      ip_list                   = optional(object({ id = string }))
      linked_app_token          = optional(object({ app_uid = string }))
      login_method              = optional(object({ id = string }))
      oidc                      = optional(object({ claim_name = string, claim_value = string, identity_provider_id = string }))
      okta                      = optional(object({ identity_provider_id = string, name = string }))
      saml                      = optional(object({ attribute_name = string, attribute_value = string, identity_provider_id = string }))
      service_token             = optional(object({ token_id = string }))
      user_risk_score           = optional(object({ user_risk_score = list(string) }))
    })))
    require = optional(list(object({
      any_valid_service_token   = optional(object({}))
      auth_context              = optional(object({ ac_id = string, id = string, identity_provider_id = string }))
      auth_method               = optional(object({ auth_method = string }))
      azure_ad                  = optional(object({ id = string, identity_provider_id = string }))
      certificate               = optional(object({}))
      cloudflare_account_member = optional(object({ account_id = optional(string) }))
      common_name               = optional(object({ common_name = string }))
      device_posture            = optional(object({ integration_uid = string }))
      email                     = optional(object({ email = string }))
      email_domain              = optional(object({ domain = string }))
      email_list                = optional(object({ id = string }))
      everyone                  = optional(object({}))
      external_evaluation       = optional(object({ evaluate_url = string, keys_url = string }))
      geo                       = optional(object({ country_code = string }))
      github_organization       = optional(object({ identity_provider_id = string, name = string, team = optional(string) }))
      group                     = optional(object({ id = string }))
      gsuite                    = optional(object({ email = string, identity_provider_id = string }))
      ip                        = optional(object({ ip = string }))
      ip_list                   = optional(object({ id = string }))
      linked_app_token          = optional(object({ app_uid = string }))
      login_method              = optional(object({ id = string }))
      oidc                      = optional(object({ claim_name = string, claim_value = string, identity_provider_id = string }))
      okta                      = optional(object({ identity_provider_id = string, name = string }))
      saml                      = optional(object({ attribute_name = string, attribute_value = string, identity_provider_id = string }))
      service_token             = optional(object({ token_id = string }))
      user_risk_score           = optional(object({ user_risk_score = list(string) }))
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      contains(["allow", "deny", "non_identity", "bypass"], p.decision)
    ])
    error_message = "Each Access policy decision must be one of allow, deny, non_identity, bypass."
  }

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      length(p.include) + length(p.include_group_keys) +
      length(p.include_service_token_keys) + length(p.include_login_method_idp_keys) > 0
    ])
    error_message = "Each Access policy must have at least one include selector, or one entry in include_group_keys, include_service_token_keys or include_login_method_idp_keys."
  }

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      alltrue([
        for a in coalesce(try(p.mfa_config.allowed_authenticators, null), []) :
        contains(["totp", "biometrics", "security_key", "ssh_piv_key"], a)
      ])
    ])
    error_message = "mfa_config.allowed_authenticators entries must be one of totp, biometrics, security_key, ssh_piv_key."
  }

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      alltrue([for g in coalesce(p.approval_groups, []) : g.approvals_needed >= 1])
    ])
    error_message = "Each approval group must require at least one approval."
  }

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      alltrue([
        for k in concat(p.include_group_keys, p.exclude_group_keys, p.require_group_keys) :
        contains(keys(var.access_groups), k)
      ])
    ])
    error_message = "Every include_group_keys, exclude_group_keys and require_group_keys entry must name a key in var.access_groups."
  }

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      alltrue([for k in p.include_service_token_keys : contains(keys(var.service_tokens), k)])
    ])
    error_message = "Every include_service_token_keys entry must name a key in var.service_tokens."
  }

  validation {
    condition = alltrue([
      for p in values(var.access_policies) :
      alltrue([for k in p.include_login_method_idp_keys : contains(keys(var.identity_providers), k)])
    ])
    error_message = "Every include_login_method_idp_keys entry must name a key in var.identity_providers."
  }
}

# -----------------------------------------------------------------------------
# Access applications and custom pages
# Passed through to modules/access-app.
# -----------------------------------------------------------------------------

variable "access_applications" {
  description = <<-EOT
    Access applications to create, keyed by a stable identifier.

    `policies` attaches reusable policies created by the access-policy submodule. Each element is
    `{ id = "<policy id>", precedence = <number> }`. Order of evaluation follows `precedence`.

    `saas_app` is only valid when `type` is `saas` or `dash_sso`. `footer_links` and `landing_page_design`
    are only valid when `type` is `app_launcher`.
  EOT
  type = map(object({
    name             = optional(string)
    type             = optional(string, "self_hosted")
    domain           = optional(string)
    session_duration = optional(string)
    allowed_idps     = optional(set(string))
    tags             = optional(set(string))
    custom_pages     = optional(list(string))

    # Keys of entries in var.access_custom_pages, resolved to page IDs inside the module
    # so an application can use a page created by this same module instance.
    custom_page_keys = optional(list(string), [])

    # Root module conveniences. Keys of entries in var.access_policies and
    # var.identity_providers, resolved to IDs before the application is created.
    policy_keys      = optional(list(string), [])
    allowed_idp_keys = optional(list(string), [])

    auto_redirect_to_identity       = optional(bool)
    app_launcher_visible            = optional(bool)
    app_launcher_logo_url           = optional(string)
    bg_color                        = optional(string)
    header_bg_color                 = optional(string)
    logo_url                        = optional(string)
    custom_deny_message             = optional(string)
    custom_deny_url                 = optional(string)
    custom_non_identity_deny_url    = optional(string)
    enable_binding_cookie           = optional(bool)
    http_only_cookie_attribute      = optional(bool)
    path_cookie_attribute           = optional(bool)
    same_site_cookie_attribute      = optional(string)
    options_preflight_bypass        = optional(bool)
    service_auth_401_redirect       = optional(bool)
    skip_interstitial               = optional(bool)
    skip_app_launcher_login_page    = optional(bool)
    allow_authenticate_via_warp     = optional(bool)
    allow_iframe                    = optional(bool)
    read_service_tokens_from_header = optional(string)

    policies = optional(list(object({
      id         = string
      precedence = optional(number)
    })), [])

    cors_headers = optional(object({
      allow_all_headers = optional(bool)
      allow_all_methods = optional(bool)
      allow_all_origins = optional(bool)
      allow_credentials = optional(bool)
      allowed_headers   = optional(set(string))
      allowed_methods   = optional(set(string))
      allowed_origins   = optional(set(string))
      max_age           = optional(number)
    }))

    destinations = optional(list(object({
      type          = optional(string)
      uri           = optional(string)
      hostname      = optional(string)
      cidr          = optional(string)
      l4_protocol   = optional(string)
      port_range    = optional(string)
      vnet_id       = optional(string)
      worker_id     = optional(string)
      mcp_server_id = optional(string)
    })))

    footer_links = optional(list(object({
      name = string
      url  = string
    })))

    landing_page_design = optional(object({
      button_color      = optional(string)
      button_text_color = optional(string)
      image_url         = optional(string)
      message           = optional(string)
      title             = optional(string)
    }))

    mfa_config = optional(object({
      allowed_authenticators = optional(list(string))
      mfa_disabled           = optional(bool)
      session_duration       = optional(string)
    }))

    oauth_configuration = optional(object({
      enabled = optional(bool)
      dynamic_client_registration = optional(object({
        allow_any_on_localhost = optional(bool)
        allow_any_on_loopback  = optional(bool)
        allowed_uris           = optional(list(string))
        enabled                = optional(bool)
      }))
      grant = optional(object({
        access_token_lifetime = optional(string)
        session_duration      = optional(string)
      }))
    }))

    target_criteria = optional(list(object({
      port              = number
      protocol          = string
      target_attributes = map(list(string))
    })))

    scim_config = optional(object({
      idp_uid              = string
      remote_uri           = string
      enabled              = optional(bool)
      deactivate_on_delete = optional(bool)
      authentication = optional(object({
        scheme            = string
        authorization_url = optional(string)
        client_id         = optional(string)
        client_secret     = optional(string)
        password          = optional(string)
        scopes            = optional(list(string))
        token             = optional(string)
        token_url         = optional(string)
        user              = optional(string)
      }))
      mappings = optional(list(object({
        schema            = string
        enabled           = optional(bool)
        filter            = optional(string)
        strictness        = optional(string)
        transform_jsonata = optional(string)
        operations = optional(object({
          create = optional(bool)
          delete = optional(bool)
          update = optional(bool)
        }))
      })))
    }))

    saas_app = optional(object({
      auth_type                        = optional(string)
      access_token_lifetime            = optional(string)
      allow_pkce_without_client_secret = optional(bool)
      app_launcher_url                 = optional(string)
      consumer_service_url             = optional(string)
      default_relay_state              = optional(string)
      grant_types                      = optional(list(string))
      group_filter_regex               = optional(string)
      idp_entity_id                    = optional(string)
      name_id_format                   = optional(string)
      name_id_transform_jsonata        = optional(string)
      redirect_uris                    = optional(list(string))
      saml_attribute_transform_jsonata = optional(string)
      scopes                           = optional(list(string))
      sp_entity_id                     = optional(string)
      sso_endpoint                     = optional(string)
      hybrid_and_implicit_options = optional(object({
        return_access_token_from_authorization_endpoint = optional(bool)
        return_id_token_from_authorization_endpoint     = optional(bool)
      }))
      refresh_token_options = optional(object({
        lifetime = optional(string)
      }))
      custom_attributes = optional(list(object({
        friendly_name = optional(string)
        name          = optional(string)
        name_format   = optional(string)
        required      = optional(bool)
        source = optional(object({
          name = optional(string)
          name_by_idp = optional(list(object({
            idp_id      = optional(string)
            source_name = optional(string)
          })))
        }))
      })))
      custom_claims = optional(list(object({
        name     = optional(string)
        required = optional(bool)
        scope    = optional(string)
        source = optional(object({
          name        = optional(string)
          name_by_idp = optional(map(string))
        }))
      })))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      contains([
        "self_hosted", "saas", "ssh", "vnc", "app_launcher", "warp", "biso", "bookmark",
        "dash_sso", "infrastructure", "rdp", "mcp", "mcp_portal", "proxy_endpoint",
      ], a.type)
    ])
    error_message = "Each application type must be one of self_hosted, saas, ssh, vnc, app_launcher, warp, biso, bookmark, dash_sso, infrastructure, rdp, mcp, mcp_portal, proxy_endpoint."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      a.saas_app == null || contains(["saas", "dash_sso"], a.type)
    ])
    error_message = "saas_app can only be set when the application type is saas or dash_sso."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      (a.footer_links == null && a.landing_page_design == null) || a.type == "app_launcher"
    ])
    error_message = "footer_links and landing_page_design can only be set when the application type is app_launcher."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      a.cors_headers == null || try(a.cors_headers.allow_all_origins, null) != null || try(a.cors_headers.allowed_origins, null) != null
    ])
    error_message = "cors_headers requires exactly one of allow_all_origins or allowed_origins."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      a.session_duration == null || can(regex("^([0-9]+(ns|us|µs|ms|s|m|h))+$", a.session_duration))
    ])
    error_message = "session_duration must look like 300ms or 24h. Valid units are ns, us, µs, ms, s, m, h."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      alltrue([
        for d in coalesce(a.destinations, []) :
        d.type == null || contains([
          "public", "private", "via_mcp_server_portal", "worker",
          "preview_worker", "all_workers", "all_preview_workers",
        ], d.type)
      ])
    ])
    error_message = "Each destination type must be one of public, private, via_mcp_server_portal, worker, preview_worker, all_workers, all_preview_workers."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      alltrue([
        for c in coalesce(try(a.target_criteria, null), []) :
        contains(["SSH", "RDP"], c.protocol)
      ])
    ])
    error_message = "target_criteria protocol must be SSH or RDP."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      a.saas_app == null || try(a.saas_app.auth_type, null) == null || contains(["saml", "oidc"], a.saas_app.auth_type)
    ])
    error_message = "saas_app.auth_type must be saml or oidc."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      alltrue([for k in a.custom_page_keys : contains(keys(var.access_custom_pages), k)])
    ])
    error_message = "Every custom_page_keys entry must name a key in var.access_custom_pages."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      alltrue([for k in a.policy_keys : contains(keys(var.access_policies), k)])
    ])
    error_message = "Every policy_keys entry must name a key in var.access_policies."
  }

  validation {
    condition = alltrue([
      for a in values(var.access_applications) :
      alltrue([for k in a.allowed_idp_keys : contains(keys(var.identity_providers), k)])
    ])
    error_message = "Every allowed_idp_keys entry must name a key in var.identity_providers."
  }
}

variable "access_custom_pages" {
  description = "Access custom pages to create, keyed by a stable identifier. Reference them from an application through its custom_pages list."
  type = map(object({
    name             = optional(string)
    type             = string
    custom_html      = string
    contract_version = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.access_custom_pages) :
      contains(["identity_denied", "forbidden", "login", "interstitial"], p.type)
    ])
    error_message = "Each custom page type must be one of identity_denied, forbidden, login, interstitial."
  }
}

# -----------------------------------------------------------------------------
# Gateway: lists, rules, settings, logging, certificates, endpoints, DNS locations
# Passed through to modules/gateway-policy.
# -----------------------------------------------------------------------------

variable "gateway_lists" {
  description = "Zero Trust lists that Gateway rules and Access policies can reference, keyed by a stable identifier."
  type = map(object({
    name        = optional(string)
    type        = string
    description = optional(string)
    items = optional(list(object({
      value       = optional(string)
      description = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for l in values(var.gateway_lists) :
      contains(["SERIAL", "URL", "DOMAIN", "EMAIL", "IP", "CATEGORY", "LOCATION", "DEVICE", "AAGUID"], l.type)
    ])
    error_message = "Each list type must be one of SERIAL, URL, DOMAIN, EMAIL, IP, CATEGORY, LOCATION, DEVICE, AAGUID."
  }
}

variable "gateway_policies" {
  description = <<-EOT
    Gateway rules, keyed by a stable identifier.

    `filters` decides which traffic the rule inspects: `dns`, `http`, `l4` or `egress`. `traffic`, `identity`
    and `device_posture` are Wirefilter expressions, for example
    `any(dns.domains[*] == "example.com")`. Lower `precedence` runs first.
  EOT
  type = map(object({
    name           = optional(string)
    description    = optional(string)
    action         = string
    enabled        = optional(bool, true)
    precedence     = optional(number)
    filters        = optional(list(string))
    traffic        = optional(string)
    identity       = optional(string)
    device_posture = optional(string)

    expiration = optional(object({
      expires_at = string
      duration   = optional(number)
    }))

    schedule = optional(object({
      mon       = optional(string)
      tue       = optional(string)
      wed       = optional(string)
      thu       = optional(string)
      fri       = optional(string)
      sat       = optional(string)
      sun       = optional(string)
      time_zone = optional(string)
    }))

    rule_settings = optional(object({
      add_headers                        = optional(map(list(string)))
      set_headers                        = optional(map(list(string)))
      delete_headers                     = optional(list(string))
      allow_child_bypass                 = optional(bool)
      bypass_parent_rule                 = optional(bool)
      block_page_enabled                 = optional(bool)
      block_reason                       = optional(string)
      ignore_cname_category_matches      = optional(bool)
      insecure_disable_dnssec_validation = optional(bool)
      ip_categories                      = optional(bool)
      ip_indicator_feeds                 = optional(bool)
      override_host                      = optional(string)
      override_ips                       = optional(list(string))
      resolve_dns_through_cloudflare     = optional(bool)

      audit_ssh = optional(object({
        command_logging = optional(bool)
      }))

      biso_admin_controls = optional(object({
        copy     = optional(string)
        dcp      = optional(bool)
        dd       = optional(bool)
        dk       = optional(bool)
        download = optional(string)
        dp       = optional(bool)
        du       = optional(bool)
        keyboard = optional(string)
        paste    = optional(string)
        printing = optional(string)
        upload   = optional(string)
        version  = optional(string)
        wm_id    = optional(string)
      }))

      block_page = optional(object({
        target_uri      = string
        include_context = optional(bool)
      }))

      check_session = optional(object({
        duration = optional(string)
        enforce  = optional(bool)
      }))

      dns_resolvers = optional(object({
        ipv4 = optional(list(object({
          ip                            = string
          port                          = optional(number)
          route_through_private_network = optional(bool)
          vnet_id                       = optional(string)
        })))
        ipv6 = optional(list(object({
          ip                            = string
          port                          = optional(number)
          route_through_private_network = optional(bool)
          vnet_id                       = optional(string)
        })))
      }))

      egress = optional(object({
        ipv4          = optional(string)
        ipv4_fallback = optional(string)
        ipv6          = optional(string)
      }))

      forensic_copy = optional(object({
        enabled = optional(bool)
      }))

      l4override = optional(object({
        ip   = optional(string)
        port = optional(number)
      }))

      notification_settings = optional(object({
        enabled         = optional(bool)
        include_context = optional(bool)
        msg             = optional(string)
        support_url     = optional(string)
      }))

      payload_log = optional(object({
        enabled = optional(bool)
      }))

      quarantine = optional(object({
        file_types = optional(list(string))
      }))

      redirect = optional(object({
        target_uri              = string
        include_context         = optional(bool)
        preserve_path_and_query = optional(bool)
      }))

      resolve_dns_internally = optional(object({
        fallback = optional(string)
        view_id  = optional(string)
      }))

      untrusted_cert = optional(object({
        action = optional(string)
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.gateway_policies) :
      contains([
        "on", "off", "allow", "block", "scan", "noscan", "safesearch", "ytrestricted",
        "isolate", "noisolate", "override", "l4_override", "egress", "resolve", "quarantine", "redirect",
      ], p.action)
    ])
    error_message = "Each Gateway policy action must be one of on, off, allow, block, scan, noscan, safesearch, ytrestricted, isolate, noisolate, override, l4_override, egress, resolve, quarantine, redirect."
  }

  validation {
    condition = alltrue([
      for p in values(var.gateway_policies) :
      alltrue([for f in coalesce(p.filters, []) : contains(["dns", "http", "l4", "egress"], f)])
    ])
    error_message = "Each Gateway policy filter must be one of dns, http, l4, egress."
  }

  validation {
    condition = alltrue([
      for p in values(var.gateway_policies) :
      try(p.rule_settings.untrusted_cert.action, null) == null ||
      contains(["pass_through", "block", "error"], p.rule_settings.untrusted_cert.action)
    ])
    error_message = "rule_settings.untrusted_cert.action must be one of pass_through, block, error."
  }

  validation {
    condition = alltrue([
      for p in values(var.gateway_policies) :
      try(p.rule_settings.resolve_dns_internally.fallback, null) == null ||
      contains(["none", "public_dns"], p.rule_settings.resolve_dns_internally.fallback)
    ])
    error_message = "rule_settings.resolve_dns_internally.fallback must be none or public_dns."
  }

  validation {
    condition = alltrue([
      for p in values(var.gateway_policies) :
      try(p.rule_settings.biso_admin_controls.version, null) == null ||
      contains(["v1", "v2"], p.rule_settings.biso_admin_controls.version)
    ])
    error_message = "rule_settings.biso_admin_controls.version must be v1 or v2."
  }
}

variable "gateway_settings" {
  description = "Account wide Gateway settings. One object per account, so leave it null to manage nothing."
  type = object({
    max_ttl_secs = optional(number)

    activity_log            = optional(object({ enabled = optional(bool) }))
    protocol_detection      = optional(object({ enabled = optional(bool) }))
    tls_decrypt             = optional(object({ enabled = optional(bool) }))
    host_selector           = optional(object({ enabled = optional(bool) }))
    fips                    = optional(object({ tls = optional(bool) }))
    body_scanning           = optional(object({ inspection_mode = optional(string) }))
    inspection              = optional(object({ mode = optional(string) }))
    certificate             = optional(object({ id = string }))
    extended_email_matching = optional(object({ enabled = optional(bool) }))

    browser_isolation = optional(object({
      non_identity_enabled          = optional(bool)
      url_browser_isolation_enabled = optional(bool)
    }))

    custom_certificate = optional(object({
      enabled = bool
      id      = optional(string)
    }))

    sandbox = optional(object({
      enabled         = optional(bool)
      fallback_action = optional(string)
    }))

    antivirus = optional(object({
      enabled_download_phase = optional(bool)
      enabled_upload_phase   = optional(bool)
      fail_closed            = optional(bool)
      notification_settings = optional(object({
        enabled         = optional(bool)
        include_context = optional(bool)
        msg             = optional(string)
        support_url     = optional(string)
      }))
    }))

    block_page = optional(object({
      background_color = optional(string)
      enabled          = optional(bool)
      footer_text      = optional(string)
      header_text      = optional(string)
      include_context  = optional(bool)
      logo_path        = optional(string)
      mailto_address   = optional(string)
      mailto_subject   = optional(string)
      mode             = optional(string)
      name             = optional(string)
      suppress_footer  = optional(bool)
      target_uri       = optional(string)
    }))
  })
  default = null
}

variable "gateway_logging" {
  description = "Account wide Gateway logging settings. One object per account, so leave it null to manage nothing."
  type = object({
    redact_pii = optional(bool)
    settings_by_rule_type = optional(object({
      dns  = optional(object({ log_all = optional(bool), log_blocks = optional(bool) }))
      http = optional(object({ log_all = optional(bool), log_blocks = optional(bool) }))
      l4   = optional(object({ log_all = optional(bool), log_blocks = optional(bool) }))
    }))
  })
  default = null
}

variable "gateway_certificates" {
  description = "Gateway inspection certificates generated by Cloudflare, keyed by a stable identifier. Setting activate on more than one certificate at a time will fight itself."
  type = map(object({
    validity_period_days = optional(number)
    activate             = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for c in values(var.gateway_certificates) :
      c.validity_period_days == null || (c.validity_period_days >= 1 && c.validity_period_days <= 10950)
    ])
    error_message = "validity_period_days must be between 1 and 10950."
  }
}

variable "gateway_proxy_endpoints" {
  description = "Gateway proxy endpoints, keyed by a stable identifier. `ips` is the list of source CIDRs allowed to use the endpoint."
  type = map(object({
    name = optional(string)
    ips  = optional(list(string))
    kind = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for e in values(var.gateway_proxy_endpoints) :
      e.kind == null || contains(["ip", "identity"], e.kind)
    ])
    error_message = "Each proxy endpoint kind must be ip or identity."
  }
}

variable "dns_locations" {
  description = "Gateway DNS locations, keyed by a stable identifier. A location maps a network or resolver endpoint to your Gateway DNS policies."
  type = map(object({
    name                   = optional(string)
    client_default         = optional(bool)
    ecs_support            = optional(bool)
    dns_destination_ips_id = optional(string)

    networks = optional(list(object({
      network = string
    })))

    max_ttl = optional(object({
      mode     = string
      ttl_secs = optional(number)
    }))

    endpoints = optional(object({
      doh = object({
        enabled       = optional(bool)
        require_token = optional(bool)
        networks      = optional(list(object({ network = string })))
      })
      dot = object({
        enabled  = optional(bool)
        networks = optional(list(object({ network = string })))
      })
      ipv4 = object({
        enabled = optional(bool)
      })
      ipv6 = object({
        enabled  = optional(bool)
        networks = optional(list(object({ network = string })))
      })
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for l in values(var.dns_locations) :
      try(l.max_ttl.mode, null) == null || contains(["inherit", "override", "disabled"], l.max_ttl.mode)
    ])
    error_message = "dns_locations max_ttl.mode must be one of inherit, override, disabled."
  }
}

# -----------------------------------------------------------------------------
# Cloudflared tunnels, virtual networks and routes
# Passed through to modules/tunnel.
# -----------------------------------------------------------------------------

variable "tunnels" {
  description = <<-EOT
    Cloudflared tunnels, keyed by a stable identifier.

    `config_src` decides who owns the ingress rules. Use `cloudflare` to manage them here through `config`,
    or `local` when the cloudflared process reads its own config file, in which case leave `config` null.

    `tunnel_secret` is a base64 encoded 32 byte secret. Leave it null and Cloudflare generates one.
  EOT
  type = map(object({
    name          = optional(string)
    config_src    = optional(string, "cloudflare")
    tunnel_secret = optional(string)

    config = optional(object({
      ingress = optional(list(object({
        service  = string
        hostname = optional(string)
        path     = optional(string)
        origin_request = optional(object({
          access = optional(object({
            aud_tag   = list(string)
            team_name = string
            required  = optional(bool)
          }))
          ca_pool                  = optional(string)
          connect_timeout          = optional(number)
          disable_chunked_encoding = optional(bool)
          http2_origin             = optional(bool)
          http_host_header         = optional(string)
          keep_alive_connections   = optional(number)
          keep_alive_timeout       = optional(number)
          match_sn_ito_host        = optional(bool)
          no_happy_eyeballs        = optional(bool)
          no_tls_verify            = optional(bool)
          origin_server_name       = optional(string)
          proxy_type               = optional(string)
          tcp_keep_alive           = optional(number)
          tls_timeout              = optional(number)
        }))
      })), [])

      origin_request = optional(object({
        access = optional(object({
          aud_tag   = list(string)
          team_name = string
          required  = optional(bool)
        }))
        ca_pool                  = optional(string)
        connect_timeout          = optional(number)
        disable_chunked_encoding = optional(bool)
        http2_origin             = optional(bool)
        http_host_header         = optional(string)
        keep_alive_connections   = optional(number)
        keep_alive_timeout       = optional(number)
        match_sn_ito_host        = optional(bool)
        no_happy_eyeballs        = optional(bool)
        no_tls_verify            = optional(bool)
        origin_server_name       = optional(string)
        proxy_type               = optional(string)
        tcp_keep_alive           = optional(number)
        tls_timeout              = optional(number)
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      contains(["local", "cloudflare"], t.config_src)
    ])
    error_message = "Each tunnel config_src must be local or cloudflare."
  }

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      t.config == null || t.config_src == "cloudflare"
    ])
    error_message = "A tunnel can only carry a config block when config_src is cloudflare. With config_src = local the cloudflared process owns its own configuration."
  }

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      t.config == null || length(coalesce(t.config.ingress, [])) == 0 ||
      alltrue([
        for r in slice(t.config.ingress, 0, max(length(t.config.ingress) - 1, 0)) :
        r.hostname != null || r.path != null
      ])
    ])
    error_message = "Only the last ingress rule may be a catch all. Every earlier rule needs a hostname or a path."
  }

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      t.config == null || length(coalesce(t.config.ingress, [])) == 0 ||
      element(t.config.ingress, length(t.config.ingress) - 1).hostname == null
    ])
    error_message = "The final ingress rule must be a catch all with no hostname, for example { service = \"http_status:404\" }."
  }
}

variable "tunnel_virtual_networks" {
  description = "Tunnel virtual networks, keyed by a stable identifier. Virtual networks let overlapping private CIDRs coexist in one account."
  type = map(object({
    name               = optional(string)
    comment            = optional(string)
    is_default_network = optional(bool)
  }))
  default = {}
}

variable "tunnel_routes" {
  description = <<-EOT
    Private network routes advertised through a tunnel, keyed by a stable identifier.

    Set `tunnel_key` to point at a tunnel created by this same module, or `tunnel_id` to point at an existing one.
    Likewise `virtual_network_key` for a virtual network created here, or `virtual_network_id` for an existing one.
  EOT
  type = map(object({
    network             = string
    comment             = optional(string)
    tunnel_key          = optional(string)
    tunnel_id           = optional(string)
    virtual_network_key = optional(string)
    virtual_network_id  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.tunnel_routes) :
      (r.tunnel_key == null) != (r.tunnel_id == null)
    ])
    error_message = "Each route must set exactly one of tunnel_key or tunnel_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.tunnel_routes) :
      r.virtual_network_key == null || r.virtual_network_id == null
    ])
    error_message = "A route cannot set both virtual_network_key and virtual_network_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.tunnel_routes) :
      can(cidrnetmask(r.network)) || can(regex(":", r.network))
    ])
    error_message = "Each route network must be a CIDR block, for example 10.0.0.0/16."
  }

  validation {
    condition = alltrue([
      for r in values(var.tunnel_routes) :
      r.tunnel_key == null || contains(keys(var.tunnels), r.tunnel_key)
    ])
    error_message = "Every route tunnel_key must name a key in var.tunnels."
  }

  validation {
    condition = alltrue([
      for r in values(var.tunnel_routes) :
      r.virtual_network_key == null || contains(keys(var.tunnel_virtual_networks), r.virtual_network_key)
    ])
    error_message = "Every route virtual_network_key must name a key in var.tunnel_virtual_networks."
  }
}

# -----------------------------------------------------------------------------
# Device posture and WARP client profiles
# Passed through to modules/device-posture.
# -----------------------------------------------------------------------------

variable "device_posture_rules" {
  description = <<-EOT
    Device posture rules, keyed by a stable identifier. `input` is a single flat object in provider v5 and the
    fields that apply depend on `type`, for example `os_version` uses operating_system, version and operator
    while `disk_encryption` uses check_disks and require_all.
  EOT
  type = map(object({
    name        = optional(string)
    type        = string
    description = optional(string)
    expiration  = optional(string)
    schedule    = optional(string)

    match = optional(list(object({
      platform = optional(string)
    })))

    input = optional(object({
      active_threats            = optional(number)
      auth_state                = optional(list(string))
      certificate_id            = optional(string)
      check_disks               = optional(list(string))
      check_private_key         = optional(bool)
      cn                        = optional(string)
      compliance_status         = optional(string)
      connection_id             = optional(string)
      count_operator            = optional(string)
      domain                    = optional(string)
      eid_last_seen             = optional(string)
      enabled                   = optional(bool)
      exists                    = optional(bool)
      extended_key_usage        = optional(list(string))
      id                        = optional(string)
      infected                  = optional(bool)
      is_active                 = optional(bool)
      issue_count               = optional(string)
      last_seen                 = optional(string)
      network_status            = optional(string)
      operating_system          = optional(string)
      operational_state         = optional(string)
      operator                  = optional(string)
      os                        = optional(string)
      os_distro_name            = optional(string)
      os_distro_revision        = optional(string)
      os_version_extra          = optional(string)
      overall                   = optional(string)
      path                      = optional(string)
      require_all               = optional(bool)
      risk_level                = optional(string)
      score                     = optional(number)
      score_operator            = optional(string)
      sensor_config             = optional(string)
      sha256                    = optional(string)
      state                     = optional(string)
      subject_alternative_names = optional(list(string))
      thumbprint                = optional(string)
      total_score               = optional(number)
      update_window_days        = optional(number)
      version                   = optional(string)
      version_operator          = optional(string)
      locations = optional(object({
        paths        = optional(list(string))
        trust_stores = optional(list(string))
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.device_posture_rules) :
      contains([
        "file", "application", "tanium", "gateway", "warp", "disk_encryption", "serial_number",
        "sentinelone", "carbonblack", "firewall", "os_version", "domain_joined", "client_certificate",
        "client_certificate_v2", "antivirus", "unique_client_id", "kolide", "tanium_s2s",
        "crowdstrike_s2s", "intune", "workspace_one", "sentinelone_s2s", "custom_s2s",
      ], r.type)
    ])
    error_message = "Each posture rule type must be one of the values the provider accepts, for example os_version, disk_encryption, firewall, client_certificate_v2 or crowdstrike_s2s."
  }

  validation {
    condition = alltrue([
      for r in values(var.device_posture_rules) :
      alltrue([
        for m in coalesce(r.match, []) :
        m.platform == null || contains(["windows", "mac", "linux", "android", "ios", "chromeos"], m.platform)
      ])
    ])
    error_message = "Each posture rule match platform must be one of windows, mac, linux, android, ios, chromeos."
  }

  validation {
    condition = alltrue([
      for r in values(var.device_posture_rules) :
      try(r.input.operator, null) == null || contains(["<", "<=", ">", ">=", "=="], r.input.operator)
    ])
    error_message = "posture rule input.operator must be one of <, <=, >, >=, ==."
  }

  validation {
    condition = alltrue([
      for r in values(var.device_posture_rules) :
      try(r.input.risk_level, null) == null || contains(["low", "medium", "high", "critical"], r.input.risk_level)
    ])
    error_message = "posture rule input.risk_level must be one of low, medium, high, critical."
  }
}

variable "device_posture_integrations" {
  description = "Third party device posture integrations, keyed by a stable identifier. `config` carries the provider credentials and is written to state."
  type = map(object({
    name     = optional(string)
    type     = string
    interval = string
    config = object({
      access_client_id     = optional(string)
      access_client_secret = optional(string)
      api_url              = optional(string)
      auth_url             = optional(string)
      client_id            = optional(string)
      client_key           = optional(string)
      client_secret        = optional(string)
      customer_id          = optional(string)
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for i in values(var.device_posture_integrations) :
      contains([
        "workspace_one", "crowdstrike_s2s", "uptycs", "intune",
        "kolide", "tanium_s2s", "sentinelone_s2s", "custom_s2s",
      ], i.type)
    ])
    error_message = "Each posture integration type must be one of workspace_one, crowdstrike_s2s, uptycs, intune, kolide, tanium_s2s, sentinelone_s2s, custom_s2s."
  }
}

variable "device_managed_networks" {
  description = "Managed networks used by device profiles to detect a trusted location, keyed by a stable identifier."
  type = map(object({
    name = optional(string)
    type = optional(string, "tls")
    config = object({
      tls_sockaddr = string
      sha256       = optional(string)
    })
  }))
  default = {}

  validation {
    condition     = alltrue([for n in values(var.device_managed_networks) : n.type == "tls"])
    error_message = "Managed network type must be tls, the only value the provider accepts."
  }
}

variable "device_settings" {
  description = "Account wide WARP device settings. One object per account, so leave it null to manage nothing."
  type = object({
    disable_for_time                      = optional(number)
    gateway_proxy_enabled                 = optional(bool)
    gateway_udp_proxy_enabled             = optional(bool)
    root_certificate_installation_enabled = optional(bool)
    use_zt_virtual_ip                     = optional(bool)
    external_emergency_signal_enabled     = optional(bool)
    external_emergency_signal_fingerprint = optional(string)
    external_emergency_signal_interval    = optional(string)
    external_emergency_signal_url         = optional(string)
  })
  default = null
}

variable "device_default_profile" {
  description = "The default WARP client profile for the account. One object per account, so leave it null to manage nothing."
  type = object({
    allow_mode_switch              = optional(bool)
    allow_updates                  = optional(bool)
    allowed_to_leave               = optional(bool)
    auto_connect                   = optional(number)
    captive_portal                 = optional(number)
    disable_auto_fallback          = optional(bool)
    exclude_office_ips             = optional(bool)
    lan_allow_minutes              = optional(number)
    lan_allow_subnet_size          = optional(number)
    register_interface_ip_with_dns = optional(bool)
    sccm_vpn_boundary_support      = optional(bool)
    support_url                    = optional(string)
    switch_locked                  = optional(bool)
    tunnel_protocol                = optional(string)

    include = optional(list(object({
      address     = optional(string)
      host        = optional(string)
      description = optional(string)
    })))
    exclude = optional(list(object({
      address     = optional(string)
      host        = optional(string)
      description = optional(string)
    })))
    dns_search_suffixes = optional(list(object({
      suffix      = string
      description = optional(string)
    })))
    service_mode_v2 = optional(object({
      mode = optional(string)
      port = optional(number)
    }))
    virtual_networks = optional(object({
      allowed = list(string)
      default = string
    }))
    global_acceleration = optional(object({
      api_endpoints       = list(string)
      enabled             = bool
      masque_endpoints    = list(string)
      wireguard_endpoints = list(string)
    }))
  })
  default = null

  validation {
    condition = var.device_default_profile == null || !(
      try(var.device_default_profile.include, null) != null && try(var.device_default_profile.exclude, null) != null
    )
    error_message = "A WARP profile uses either split tunnel include mode or exclude mode, never both."
  }
}

variable "device_custom_profiles" {
  description = "Additional WARP client profiles selected by a `match` expression, keyed by a stable identifier. Lower `precedence` wins."
  type = map(object({
    name                           = optional(string)
    match                          = string
    description                    = optional(string)
    enabled                        = optional(bool)
    precedence                     = optional(number)
    allow_mode_switch              = optional(bool)
    allow_updates                  = optional(bool)
    allowed_to_leave               = optional(bool)
    auto_connect                   = optional(number)
    captive_portal                 = optional(number)
    disable_auto_fallback          = optional(bool)
    exclude_office_ips             = optional(bool)
    lan_allow_minutes              = optional(number)
    lan_allow_subnet_size          = optional(number)
    register_interface_ip_with_dns = optional(bool)
    sccm_vpn_boundary_support      = optional(bool)
    support_url                    = optional(string)
    switch_locked                  = optional(bool)
    tunnel_protocol                = optional(string)

    include = optional(list(object({
      address     = optional(string)
      host        = optional(string)
      description = optional(string)
    })))
    exclude = optional(list(object({
      address     = optional(string)
      host        = optional(string)
      description = optional(string)
    })))
    dns_search_suffixes = optional(list(object({
      suffix      = string
      description = optional(string)
    })))
    service_mode_v2 = optional(object({
      mode = optional(string)
      port = optional(number)
    }))
    virtual_networks = optional(object({
      allowed = list(string)
      default = string
    }))
    global_acceleration = optional(object({
      api_endpoints       = list(string)
      enabled             = bool
      masque_endpoints    = list(string)
      wireguard_endpoints = list(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.device_custom_profiles) :
      !(p.include != null && p.exclude != null)
    ])
    error_message = "A WARP profile uses either split tunnel include mode or exclude mode, never both."
  }
}

# -----------------------------------------------------------------------------
# Data Loss Prevention
# Passed through to modules/dlp.
# -----------------------------------------------------------------------------

variable "dlp_profiles" {
  description = <<-EOT
    Custom DLP profiles, keyed by a stable identifier.

    `entries` are detections owned by the profile and defined inline. `shared_entries` reference detections that
    already exist, such as Cloudflare predefined entries or entries from a dataset.
  EOT
  type = map(object({
    name                 = optional(string)
    description          = optional(string)
    ai_context_enabled   = optional(bool)
    allowed_match_count  = optional(number)
    confidence_threshold = optional(string)
    ocr_enabled          = optional(bool)
    data_classes         = optional(list(string))
    data_tags            = optional(list(string))

    context_awareness = optional(object({
      enabled = optional(bool)
      skip    = optional(object({ files = optional(bool) }))
    }))

    entries = optional(list(object({
      name        = string
      enabled     = bool
      description = optional(string)
      entry_id    = optional(string)
      pattern = object({
        regex      = string
        validation = optional(string)
      })
    })), [])

    shared_entries = optional(list(object({
      enabled    = bool
      entry_id   = string
      entry_type = string
    })), [])

    sensitivity_levels = optional(list(object({
      group_id = string
      level_id = string
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.dlp_profiles) :
      alltrue([for e in p.entries : e.pattern.validation == null || e.pattern.validation == "luhn"])
    ])
    error_message = "The only DLP pattern validation the provider accepts is luhn."
  }

  validation {
    condition = alltrue([
      for p in values(var.dlp_profiles) :
      alltrue([
        for e in p.shared_entries :
        contains(["custom", "predefined", "integration", "exact_data", "document_fingerprint"], e.entry_type)
      ])
    ])
    error_message = "Each shared entry entry_type must be one of custom, predefined, integration, exact_data, document_fingerprint."
  }

  validation {
    condition = alltrue([
      for p in values(var.dlp_profiles) :
      alltrue([for e in p.entries : can(regex("", e.pattern.regex)) && length(e.pattern.regex) > 0])
    ])
    error_message = "Every DLP entry pattern regex must be a non empty string."
  }
}

variable "dlp_entries" {
  description = "Standalone custom DLP entries, keyed by a stable identifier. Set `profile_key` to attach one to a profile created by this module, or `profile_id` to attach it to an existing profile."
  type = map(object({
    name        = optional(string)
    enabled     = bool
    description = optional(string)
    profile_key = optional(string)
    profile_id  = optional(string)
    pattern = object({
      regex      = string
      validation = optional(string)
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for e in values(var.dlp_entries) :
      e.profile_key == null || e.profile_id == null
    ])
    error_message = "A DLP entry cannot set both profile_key and profile_id."
  }

  validation {
    condition = alltrue([
      for e in values(var.dlp_entries) :
      e.profile_key == null || contains(keys(var.dlp_profiles), e.profile_key)
    ])
    error_message = "Every DLP entry profile_key must name a key in var.dlp_profiles."
  }

  validation {
    condition = alltrue([
      for e in values(var.dlp_entries) :
      e.pattern.validation == null || e.pattern.validation == "luhn"
    ])
    error_message = "The only DLP pattern validation the provider accepts is luhn."
  }
}

variable "dlp_datasets" {
  description = "DLP datasets for exact data match and document fingerprinting, keyed by a stable identifier. Upload the cell data out of band, Terraform only manages the container."
  type = map(object({
    name             = optional(string)
    description      = optional(string)
    case_sensitive   = optional(bool)
    encoding_version = optional(number)
    secret           = optional(bool)
    dataset_id       = optional(string)
  }))
  default = {}
}

variable "dlp_settings" {
  description = "Account wide DLP settings. One object per account, so leave it null to manage nothing."
  type = object({
    ai_context_analysis = optional(bool)
    ocr                 = optional(bool)
    payload_logging = optional(object({
      masking_level = optional(string)
      public_key    = optional(string)
    }))
  })
  default = null

  validation {
    condition = (
      var.dlp_settings == null ||
      try(var.dlp_settings.payload_logging.masking_level, null) == null ||
      contains(["full", "partial", "clear", "default"], var.dlp_settings.payload_logging.masking_level)
    )
    error_message = "payload_logging.masking_level must be one of full, partial, clear, default."
  }
}
