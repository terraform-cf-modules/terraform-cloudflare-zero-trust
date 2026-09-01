variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the applications. Set this or zone_id, not both."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID that owns the applications. Set this or account_id, not both."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "applications" {
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

    # Keys of entries in var.custom_pages, resolved to page IDs inside the module
    # so an application can use a page created by this same module instance.
    custom_page_keys                = optional(list(string), [])
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
      for a in values(var.applications) :
      contains([
        "self_hosted", "saas", "ssh", "vnc", "app_launcher", "warp", "biso", "bookmark",
        "dash_sso", "infrastructure", "rdp", "mcp", "mcp_portal", "proxy_endpoint",
      ], a.type)
    ])
    error_message = "Each application type must be one of self_hosted, saas, ssh, vnc, app_launcher, warp, biso, bookmark, dash_sso, infrastructure, rdp, mcp, mcp_portal, proxy_endpoint."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      a.saas_app == null || contains(["saas", "dash_sso"], a.type)
    ])
    error_message = "saas_app can only be set when the application type is saas or dash_sso."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      (a.footer_links == null && a.landing_page_design == null) || a.type == "app_launcher"
    ])
    error_message = "footer_links and landing_page_design can only be set when the application type is app_launcher."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      a.app_launcher_visible == null ||
      contains(["self_hosted", "ssh", "vnc", "rdp", "saas", "bookmark"], a.type)
    ])
    error_message = "app_launcher_visible can only be set when the application type is one of self_hosted, ssh, vnc, rdp, saas, bookmark."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      a.cors_headers == null || try(a.cors_headers.allow_all_origins, null) != null || try(a.cors_headers.allowed_origins, null) != null
    ])
    error_message = "cors_headers requires exactly one of allow_all_origins or allowed_origins."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      a.session_duration == null || can(regex("^([0-9]+(ns|us|µs|ms|s|m|h))+$", a.session_duration))
    ])
    error_message = "session_duration must look like 300ms or 24h. Valid units are ns, us, µs, ms, s, m, h."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
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
      for a in values(var.applications) :
      alltrue([
        for c in coalesce(try(a.target_criteria, null), []) :
        contains(["SSH", "RDP"], c.protocol)
      ])
    ])
    error_message = "target_criteria protocol must be SSH or RDP."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      a.saas_app == null || try(a.saas_app.auth_type, null) == null || contains(["saml", "oidc"], a.saas_app.auth_type)
    ])
    error_message = "saas_app.auth_type must be saml or oidc."
  }

  validation {
    condition = alltrue([
      for a in values(var.applications) :
      alltrue([for k in a.custom_page_keys : contains(keys(var.custom_pages), k)])
    ])
    error_message = "Every custom_page_keys entry must name a key in var.custom_pages."
  }
}

variable "custom_pages" {
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
      for p in values(var.custom_pages) :
      contains(["identity_denied", "forbidden", "login", "interstitial"], p.type)
    ])
    error_message = "Each custom page type must be one of identity_denied, forbidden, login, interstitial."
  }
}
