# Submodule: dlp

Data Loss Prevention profiles, detections and datasets.

| Terraform resource | v4 name | Purpose |
|--------------------|---------|---------|
| `cloudflare_zero_trust_dlp_custom_profile` | `cloudflare_dlp_profile` | A named set of detections |
| `cloudflare_zero_trust_dlp_custom_entry` | — | A standalone detection attached to a profile |
| `cloudflare_zero_trust_dlp_dataset` | `cloudflare_dlp_dataset` | Exact data match and document fingerprint container |
| `cloudflare_zero_trust_dlp_settings` | — | Account wide OCR and payload logging |

## Inline entries or standalone entries, not both

A detection can be declared inline on the profile through `entries`, or as its own
`cloudflare_zero_trust_dlp_custom_entry` resource pointed at a profile. Managing the same detection both ways
makes the two resources overwrite each other on every apply. Pick one per detection.

Prefer standalone entries. Provider 5.24 marks the inline `entries` list as scheduled for sunset on
01/01/2026, and planning with it set emits a deprecation warning. `context_awareness` on a profile is likewise
deprecated and is deliberately not exposed by this module.

```hcl
profiles = {
  pii = {
    entries = [
      {
        name    = "Employee ID"
        enabled = true
        pattern = { regex = "EMP-[0-9]{6}" }
      },
    ]
  }
}

# or, equivalently, as a standalone entry
entries = {
  employee_id = {
    enabled     = true
    profile_key = "pii"
    pattern     = { regex = "EMP-[0-9]{6}" }
  }
}
```

## Datasets

Terraform manages the dataset container. The cell data itself is uploaded through the Cloudflare API or dashboard,
so a dataset created here starts empty and reports `status = "empty"` until you upload to it.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID. Every DLP resource is account scoped. | `string` | `null` | no |
| <a name="input_datasets"></a> [datasets](#input\_datasets) | DLP datasets for exact data match and document fingerprinting, keyed by a stable identifier. Upload the cell data out of band, Terraform only manages the container. | <pre>map(object({<br/>    name             = optional(string)<br/>    description      = optional(string)<br/>    case_sensitive   = optional(bool)<br/>    encoding_version = optional(number)<br/>    secret           = optional(bool)<br/>    dataset_id       = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_entries"></a> [entries](#input\_entries) | Standalone custom DLP entries, keyed by a stable identifier. Set `profile_key` to attach one to a profile created by this module, or `profile_id` to attach it to an existing profile. | <pre>map(object({<br/>    name        = optional(string)<br/>    enabled     = bool<br/>    description = optional(string)<br/>    profile_key = optional(string)<br/>    profile_id  = optional(string)<br/>    pattern = object({<br/>      regex      = string<br/>      validation = optional(string)<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_profiles"></a> [profiles](#input\_profiles) | Custom DLP profiles, keyed by a stable identifier.<br/><br/>`entries` are detections owned by the profile and defined inline. `shared_entries` reference detections that<br/>already exist, such as Cloudflare predefined entries or entries from a dataset. | <pre>map(object({<br/>    name                 = optional(string)<br/>    description          = optional(string)<br/>    ai_context_enabled   = optional(bool)<br/>    allowed_match_count  = optional(number)<br/>    confidence_threshold = optional(string)<br/>    ocr_enabled          = optional(bool)<br/>    data_classes         = optional(list(string))<br/>    data_tags            = optional(list(string))<br/><br/>    entries = optional(list(object({<br/>      name        = string<br/>      enabled     = bool<br/>      description = optional(string)<br/>      entry_id    = optional(string)<br/>      pattern = object({<br/>        regex      = string<br/>        validation = optional(string)<br/>      })<br/>    })), [])<br/><br/>    shared_entries = optional(list(object({<br/>      enabled    = bool<br/>      entry_id   = string<br/>      entry_type = string<br/>    })), [])<br/><br/>    sensitivity_levels = optional(list(object({<br/>      group_id = string<br/>      level_id = string<br/>    })))<br/>  }))</pre> | `{}` | no |
| <a name="input_settings"></a> [settings](#input\_settings) | Account wide DLP settings. One object per account, so leave it null to manage nothing. | <pre>object({<br/>    ai_context_analysis = optional(bool)<br/>    ocr                 = optional(bool)<br/>    payload_logging = optional(object({<br/>      masking_level = optional(string)<br/>      public_key    = optional(string)<br/>    }))<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dataset_ids"></a> [dataset\_ids](#output\_dataset\_ids) | Map of DLP dataset key to dataset ID. |
| <a name="output_datasets"></a> [datasets](#output\_datasets) | Full DLP dataset objects, keyed by the same keys as var.datasets. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_entries"></a> [entries](#output\_entries) | Full DLP entry objects, keyed by the same keys as var.entries. |
| <a name="output_entry_ids"></a> [entry\_ids](#output\_entry\_ids) | Map of DLP entry key to entry ID. |
| <a name="output_profile_ids"></a> [profile\_ids](#output\_profile\_ids) | Map of DLP profile key to profile ID. Reference these from a Gateway HTTP policy expression. |
| <a name="output_profiles"></a> [profiles](#output\_profiles) | Full DLP profile objects, keyed by the same keys as var.profiles. |
| <a name="output_settings"></a> [settings](#output\_settings) | The account wide DLP settings object, or null when this module does not manage it. |
<!-- END_TF_DOCS -->
