variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID. Every Gateway resource is account scoped."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

# -----------------------------------------------------------------------------
# Lists
# -----------------------------------------------------------------------------

variable "lists" {
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
      for l in values(var.lists) :
      contains(["SERIAL", "URL", "DOMAIN", "EMAIL", "IP", "CATEGORY", "LOCATION", "DEVICE", "AAGUID"], l.type)
    ])
    error_message = "Each list type must be one of SERIAL, URL, DOMAIN, EMAIL, IP, CATEGORY, LOCATION, DEVICE, AAGUID."
  }
}

# -----------------------------------------------------------------------------
# Policies
# -----------------------------------------------------------------------------

variable "policies" {
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
      for p in values(var.policies) :
      contains([
        "on", "off", "allow", "block", "scan", "noscan", "safesearch", "ytrestricted",
        "isolate", "noisolate", "override", "l4_override", "egress", "resolve", "quarantine", "redirect",
      ], p.action)
    ])
    error_message = "Each Gateway policy action must be one of on, off, allow, block, scan, noscan, safesearch, ytrestricted, isolate, noisolate, override, l4_override, egress, resolve, quarantine, redirect."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      alltrue([for f in coalesce(p.filters, []) : contains(["dns", "http", "l4", "egress"], f)])
    ])
    error_message = "Each Gateway policy filter must be one of dns, http, l4, egress."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      try(p.rule_settings.untrusted_cert.action, null) == null ||
      contains(["pass_through", "block", "error"], p.rule_settings.untrusted_cert.action)
    ])
    error_message = "rule_settings.untrusted_cert.action must be one of pass_through, block, error."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      try(p.rule_settings.resolve_dns_internally.fallback, null) == null ||
      contains(["none", "public_dns"], p.rule_settings.resolve_dns_internally.fallback)
    ])
    error_message = "rule_settings.resolve_dns_internally.fallback must be none or public_dns."
  }

  validation {
    condition = alltrue([
      for p in values(var.policies) :
      try(p.rule_settings.biso_admin_controls.version, null) == null ||
      contains(["v1", "v2"], p.rule_settings.biso_admin_controls.version)
    ])
    error_message = "rule_settings.biso_admin_controls.version must be v1 or v2."
  }
}

# -----------------------------------------------------------------------------
# Account wide Gateway configuration
# -----------------------------------------------------------------------------

variable "settings" {
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

variable "logging" {
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

variable "certificates" {
  description = "Gateway inspection certificates generated by Cloudflare, keyed by a stable identifier. Setting activate on more than one certificate at a time will fight itself."
  type = map(object({
    validity_period_days = optional(number)
    activate             = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for c in values(var.certificates) :
      c.validity_period_days == null || (c.validity_period_days >= 1 && c.validity_period_days <= 10950)
    ])
    error_message = "validity_period_days must be between 1 and 10950."
  }
}

variable "proxy_endpoints" {
  description = "Gateway proxy endpoints, keyed by a stable identifier. `ips` is the list of source CIDRs allowed to use the endpoint."
  type = map(object({
    name = optional(string)
    ips  = optional(list(string))
    kind = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for e in values(var.proxy_endpoints) :
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
