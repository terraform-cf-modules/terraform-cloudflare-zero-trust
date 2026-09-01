# Submodule: device-posture

Device posture signals and the WARP client profiles that consume them.

| Terraform resource | v4 name | Purpose |
|--------------------|---------|---------|
| `cloudflare_zero_trust_device_posture_rule` | `cloudflare_device_posture_rule` | A single posture check |
| `cloudflare_zero_trust_device_posture_integration` | `cloudflare_device_posture_integration` | Third party MDM or EDR feed |
| `cloudflare_zero_trust_device_custom_profile` | `cloudflare_device_settings_policy` | WARP profile matched by expression |
| `cloudflare_zero_trust_device_default_profile` | `cloudflare_device_settings_policy` with `default` | Fallback WARP profile |
| `cloudflare_zero_trust_device_managed_networks` | `cloudflare_device_managed_networks` | Trusted network detection |
| `cloudflare_zero_trust_device_settings` | `cloudflare_device_settings` | Account wide WARP behaviour |

## Posture rule input

`input` was a repeatable block in v4 and is a single flat object in v5. Which fields apply depends on `type`:

```hcl
posture_rules = {
  min_macos = {
    type  = "os_version"
    match = [{ platform = "mac" }]
    input = {
      operating_system = "mac"
      version          = "14.0.0"
      operator         = ">="
    }
  }

  disk_encrypted = {
    type  = "disk_encryption"
    match = [{ platform = "mac" }, { platform = "windows" }]
    input = {
      require_all = true
      check_disks = ["C"]
    }
  }
}
```

Feed `posture_rule_ids` into a Gateway policy `device_posture` expression, or
`posture_integration_ids` into an Access policy `{ device_posture = { integration_uid = ... } }` selector.

## Split tunnel mode

A WARP profile is either include mode or exclude mode. Setting both `include` and `exclude` is rejected by a
`validation` block before the provider sees it.

## Singletons

`device_settings` and `default_profile` are one object per account. Leave them null and the resources are not
created, so two stacks do not overwrite each other.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID. Every device resource is account scoped. | `string` | `null` | no |
| <a name="input_custom_profiles"></a> [custom\_profiles](#input\_custom\_profiles) | Additional WARP client profiles selected by a `match` expression, keyed by a stable identifier. Lower `precedence` wins. | <pre>map(object({<br/>    name                           = optional(string)<br/>    match                          = string<br/>    description                    = optional(string)<br/>    enabled                        = optional(bool)<br/>    precedence                     = optional(number)<br/>    allow_mode_switch              = optional(bool)<br/>    allow_updates                  = optional(bool)<br/>    allowed_to_leave               = optional(bool)<br/>    auto_connect                   = optional(number)<br/>    captive_portal                 = optional(number)<br/>    disable_auto_fallback          = optional(bool)<br/>    exclude_office_ips             = optional(bool)<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    support_url                    = optional(string)<br/>    switch_locked                  = optional(bool)<br/>    tunnel_protocol                = optional(string)<br/><br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      host        = optional(string)<br/>      description = optional(string)<br/>    })))<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      host        = optional(string)<br/>      description = optional(string)<br/>    })))<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_default_profile"></a> [default\_profile](#input\_default\_profile) | The default WARP client profile for the account. One object per account, so leave it null to manage nothing. | <pre>object({<br/>    allow_mode_switch              = optional(bool)<br/>    allow_updates                  = optional(bool)<br/>    allowed_to_leave               = optional(bool)<br/>    auto_connect                   = optional(number)<br/>    captive_portal                 = optional(number)<br/>    disable_auto_fallback          = optional(bool)<br/>    exclude_office_ips             = optional(bool)<br/>    lan_allow_minutes              = optional(number)<br/>    lan_allow_subnet_size          = optional(number)<br/>    register_interface_ip_with_dns = optional(bool)<br/>    sccm_vpn_boundary_support      = optional(bool)<br/>    support_url                    = optional(string)<br/>    switch_locked                  = optional(bool)<br/>    tunnel_protocol                = optional(string)<br/><br/>    include = optional(list(object({<br/>      address     = optional(string)<br/>      host        = optional(string)<br/>      description = optional(string)<br/>    })))<br/>    exclude = optional(list(object({<br/>      address     = optional(string)<br/>      host        = optional(string)<br/>      description = optional(string)<br/>    })))<br/>    dns_search_suffixes = optional(list(object({<br/>      suffix      = string<br/>      description = optional(string)<br/>    })))<br/>    service_mode_v2 = optional(object({<br/>      mode = optional(string)<br/>      port = optional(number)<br/>    }))<br/>    virtual_networks = optional(object({<br/>      allowed = list(string)<br/>      default = string<br/>    }))<br/>    global_acceleration = optional(object({<br/>      api_endpoints       = list(string)<br/>      enabled             = bool<br/>      masque_endpoints    = list(string)<br/>      wireguard_endpoints = list(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_device_settings"></a> [device\_settings](#input\_device\_settings) | Account wide WARP device settings. One object per account, so leave it null to manage nothing. | <pre>object({<br/>    disable_for_time                      = optional(number)<br/>    gateway_proxy_enabled                 = optional(bool)<br/>    gateway_udp_proxy_enabled             = optional(bool)<br/>    root_certificate_installation_enabled = optional(bool)<br/>    use_zt_virtual_ip                     = optional(bool)<br/>    external_emergency_signal_enabled     = optional(bool)<br/>    external_emergency_signal_fingerprint = optional(string)<br/>    external_emergency_signal_interval    = optional(string)<br/>    external_emergency_signal_url         = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_managed_networks"></a> [managed\_networks](#input\_managed\_networks) | Managed networks used by device profiles to detect a trusted location, keyed by a stable identifier. | <pre>map(object({<br/>    name = optional(string)<br/>    type = optional(string, "tls")<br/>    config = object({<br/>      tls_sockaddr = string<br/>      sha256       = optional(string)<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_posture_integrations"></a> [posture\_integrations](#input\_posture\_integrations) | Third party device posture integrations, keyed by a stable identifier. `config` carries the provider credentials and is written to state. | <pre>map(object({<br/>    name     = optional(string)<br/>    type     = string<br/>    interval = string<br/>    config = object({<br/>      access_client_id     = optional(string)<br/>      access_client_secret = optional(string)<br/>      api_url              = optional(string)<br/>      auth_url             = optional(string)<br/>      client_id            = optional(string)<br/>      client_key           = optional(string)<br/>      client_secret        = optional(string)<br/>      customer_id          = optional(string)<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_posture_rules"></a> [posture\_rules](#input\_posture\_rules) | Device posture rules, keyed by a stable identifier. `input` is a single flat object in provider v5 and the<br/>fields that apply depend on `type`, for example `os_version` uses operating\_system, version and operator<br/>while `disk_encryption` uses check\_disks and require\_all. | <pre>map(object({<br/>    name        = optional(string)<br/>    type        = string<br/>    description = optional(string)<br/>    expiration  = optional(string)<br/>    schedule    = optional(string)<br/><br/>    match = optional(list(object({<br/>      platform = optional(string)<br/>    })))<br/><br/>    input = optional(object({<br/>      active_threats            = optional(number)<br/>      auth_state                = optional(list(string))<br/>      certificate_id            = optional(string)<br/>      check_disks               = optional(list(string))<br/>      check_private_key         = optional(bool)<br/>      cn                        = optional(string)<br/>      compliance_status         = optional(string)<br/>      connection_id             = optional(string)<br/>      count_operator            = optional(string)<br/>      domain                    = optional(string)<br/>      eid_last_seen             = optional(string)<br/>      enabled                   = optional(bool)<br/>      exists                    = optional(bool)<br/>      extended_key_usage        = optional(list(string))<br/>      id                        = optional(string)<br/>      infected                  = optional(bool)<br/>      is_active                 = optional(bool)<br/>      issue_count               = optional(string)<br/>      last_seen                 = optional(string)<br/>      network_status            = optional(string)<br/>      operating_system          = optional(string)<br/>      operational_state         = optional(string)<br/>      operator                  = optional(string)<br/>      os                        = optional(string)<br/>      os_distro_name            = optional(string)<br/>      os_distro_revision        = optional(string)<br/>      os_version_extra          = optional(string)<br/>      overall                   = optional(string)<br/>      path                      = optional(string)<br/>      require_all               = optional(bool)<br/>      risk_level                = optional(string)<br/>      score                     = optional(number)<br/>      score_operator            = optional(string)<br/>      sensor_config             = optional(string)<br/>      sha256                    = optional(string)<br/>      state                     = optional(string)<br/>      subject_alternative_names = optional(list(string))<br/>      thumbprint                = optional(string)<br/>      total_score               = optional(number)<br/>      update_window_days        = optional(number)<br/>      version                   = optional(string)<br/>      version_operator          = optional(string)<br/>      locations = optional(object({<br/>        paths        = optional(list(string))<br/>        trust_stores = optional(list(string))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_custom_profile_ids"></a> [custom\_profile\_ids](#output\_custom\_profile\_ids) | Map of custom profile key to profile ID. |
| <a name="output_custom_profiles"></a> [custom\_profiles](#output\_custom\_profiles) | Full custom WARP profile objects, keyed by the same keys as var.custom\_profiles. |
| <a name="output_default_profile"></a> [default\_profile](#output\_default\_profile) | The default WARP profile object, or null when this module does not manage it. |
| <a name="output_device_settings"></a> [device\_settings](#output\_device\_settings) | The account wide device settings object, or null when this module does not manage it. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_managed_network_ids"></a> [managed\_network\_ids](#output\_managed\_network\_ids) | Map of managed network key to network ID. |
| <a name="output_managed_networks"></a> [managed\_networks](#output\_managed\_networks) | Full managed network objects, keyed by the same keys as var.managed\_networks. |
| <a name="output_posture_integration_ids"></a> [posture\_integration\_ids](#output\_posture\_integration\_ids) | Map of posture integration key to integration ID. Use these as integration\_uid in an Access device\_posture selector. |
| <a name="output_posture_integrations"></a> [posture\_integrations](#output\_posture\_integrations) | Full posture integration objects. Marked sensitive because config carries provider credentials. |
| <a name="output_posture_rule_ids"></a> [posture\_rule\_ids](#output\_posture\_rule\_ids) | Map of posture rule key to rule ID. Use these in a Gateway device\_posture expression. |
| <a name="output_posture_rules"></a> [posture\_rules](#output\_posture\_rules) | Full posture rule objects, keyed by the same keys as var.posture\_rules. |
<!-- END_TF_DOCS -->
