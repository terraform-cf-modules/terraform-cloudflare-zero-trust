variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID. Every device resource is account scoped."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "posture_rules" {
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
      for r in values(var.posture_rules) :
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
      for r in values(var.posture_rules) :
      alltrue([
        for m in coalesce(r.match, []) :
        m.platform == null || contains(["windows", "mac", "linux", "android", "ios", "chromeos"], m.platform)
      ])
    ])
    error_message = "Each posture rule match platform must be one of windows, mac, linux, android, ios, chromeos."
  }

  validation {
    condition = alltrue([
      for r in values(var.posture_rules) :
      try(r.input.operator, null) == null || contains(["<", "<=", ">", ">=", "=="], r.input.operator)
    ])
    error_message = "posture rule input.operator must be one of <, <=, >, >=, ==."
  }

  validation {
    condition = alltrue([
      for r in values(var.posture_rules) :
      try(r.input.risk_level, null) == null || contains(["low", "medium", "high", "critical"], r.input.risk_level)
    ])
    error_message = "posture rule input.risk_level must be one of low, medium, high, critical."
  }
}

variable "posture_integrations" {
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
      for i in values(var.posture_integrations) :
      contains([
        "workspace_one", "crowdstrike_s2s", "uptycs", "intune",
        "kolide", "tanium_s2s", "sentinelone_s2s", "custom_s2s",
      ], i.type)
    ])
    error_message = "Each posture integration type must be one of workspace_one, crowdstrike_s2s, uptycs, intune, kolide, tanium_s2s, sentinelone_s2s, custom_s2s."
  }
}

variable "managed_networks" {
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
    condition     = alltrue([for n in values(var.managed_networks) : n.type == "tls"])
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

variable "default_profile" {
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
    condition = var.default_profile == null || !(
      try(var.default_profile.include, null) != null && try(var.default_profile.exclude, null) != null
    )
    error_message = "A WARP profile uses either split tunnel include mode or exclude mode, never both."
  }
}

variable "custom_profiles" {
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
      for p in values(var.custom_profiles) :
      !(p.include != null && p.exclude != null)
    ])
    error_message = "A WARP profile uses either split tunnel include mode or exclude mode, never both."
  }
}
