variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the identity providers and mTLS certificates."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID, for zone scoped identity providers and mTLS certificates."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

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
