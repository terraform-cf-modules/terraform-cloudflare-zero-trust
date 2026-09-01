variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the Access groups, policies and tags."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID, used only for zone scoped Access groups. Access policies and tags are account scoped."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

# -----------------------------------------------------------------------------
# Access tags
# -----------------------------------------------------------------------------

variable "access_tags" {
  description = "Access tags to create, keyed by a stable identifier. Tags group applications in the Zero Trust dashboard."
  type = map(object({
    name = optional(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Access groups
#
# include, exclude and require share one selector object. Set exactly one field
# on each element. The shape mirrors the provider schema one to one, so an
# element such as { email_domain = { domain = "example.com" } } is valid.
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# Access policies
# -----------------------------------------------------------------------------

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
      length(p.include) + length(p.include_group_keys) > 0
    ])
    error_message = "Each Access policy must have at least one include selector or include_group_keys entry."
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
}
