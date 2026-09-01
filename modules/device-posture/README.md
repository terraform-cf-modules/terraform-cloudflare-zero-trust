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
<!-- END_TF_DOCS -->
