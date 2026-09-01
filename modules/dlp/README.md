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
<!-- END_TF_DOCS -->
