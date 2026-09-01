# Submodule: access-app

Access applications and Access custom pages.

| Terraform resource | Purpose |
|--------------------|---------|
| `cloudflare_zero_trust_access_application` | The protected application |
| `cloudflare_zero_trust_access_custom_page` | Branded block, login and interstitial pages |

## Attaching policies

Provider v5 has no `cloudflare_access_application_policy` join resource and no `application_id` on a policy.
An application lists the policies it uses:

```hcl
policies = [
  { id = module.policies.access_policy_ids.allow_engineering, precedence = 1 },
  { id = module.policies.access_policy_ids.block_contractors, precedence = 2 },
]
```

## Custom pages

An application references custom pages by ID. Create the page here and name it with `custom_page_keys`, and the
module resolves the ID for you:

```hcl
custom_pages = {
  denied = { type = "forbidden", custom_html = file("${path.module}/denied.html") }
}

applications = {
  internal = {
    custom_page_keys = ["denied"]
  }
}
```

## Attribute combinations the provider enforces

| Attribute | Allowed only when |
|-----------|-------------------|
| `saas_app` | `type` is `saas` or `dash_sso` |
| `footer_links`, `landing_page_design` | `type` is `app_launcher` |
| `cors_headers` | exactly one of `allow_all_origins` or `allowed_origins` is set |
| `app_launcher_visible` | `type` is one of `self_hosted`, `ssh`, `vnc`, `rdp`, `saas`, `bookmark`, that is, **not** `app_launcher` |

`self_hosted_domains` is deprecated in v5 and is deliberately not exposed. Use `destinations` instead:

```hcl
destinations = [{ type = "public", uri = "app.example.com" }]
```

## Usage

```hcl
module "app" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/access-app"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  applications = {
    internal = {
      name             = "Internal Tools"
      type             = "self_hosted"
      domain           = "tools.example.com"
      session_duration = "24h"
      destinations     = [{ type = "public", uri = "tools.example.com" }]
      policies         = [{ id = var.policy_id, precedence = 1 }]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
