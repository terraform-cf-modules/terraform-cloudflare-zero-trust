# Submodule: access-policy

Reusable Access policies, Access groups and Access tags.

| Terraform resource | Purpose |
|--------------------|---------|
| `cloudflare_zero_trust_access_policy` | Reusable allow/deny/bypass rule |
| `cloudflare_zero_trust_access_group`  | Named set of selectors reused across policies |
| `cloudflare_zero_trust_access_tag`    | Tag applications for the App Launcher |

In provider v5 a policy is a standalone object. It no longer lives inside an application and no longer has an
`application_id`. Create the policy here, then attach it by ID through the application's `policies` list, which the
`access-app` submodule exposes.

## Rule shape

`include`, `exclude` and `require` are lists of selector objects. Every selector key is optional and you set
exactly one per element. The shape is taken from the provider schema verbatim:

```hcl
include = [
  { email_domain = { domain = "example.com" } },
  { group = { id = "de6f5e6c9d4a4e6f9c4c1f0d2b3a4c5d" } },
]
require = [
  { auth_method = { auth_method = "mfa" } },
]
```

Selector keys with no fields of their own are written as an empty object:

```hcl
include = [{ everyone = {} }]
exclude = [{ any_valid_service_token = {} }]
```

Available selectors: `any_valid_service_token`, `auth_context`, `auth_method`, `azure_ad`, `certificate`,
`cloudflare_account_member`, `common_name`, `device_posture`, `email`, `email_domain`, `email_list`, `everyone`,
`external_evaluation`, `geo`, `github_organization`, `group`, `gsuite`, `ip`, `ip_list`, `linked_app_token`,
`login_method`, `oidc`, `okta`, `saml`, `service_token`, `user_risk_score`.

## Referencing a group created by the same module

A policy cannot reference `module.<this>.access_group_ids` from inside its own module block, that is a cycle.
Use `include_group_keys`, `exclude_group_keys` and `require_group_keys` instead. Each entry names a key in
`var.access_groups` and is resolved to a `group` selector inside the module.

## Usage

```hcl
module "policies" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/access-policy"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  access_groups = {
    engineering = {
      include = [{ email_domain = { domain = "example.com" } }]
    }
  }

  access_policies = {
    allow_engineering = {
      decision           = "allow"
      session_duration   = "24h"
      include            = []
      include_group_keys = ["engineering"]
      require            = [{ auth_method = { auth_method = "mfa" } }]
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
