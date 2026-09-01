<p align="center">
  <img width="1000" alt="CloudDrove Banner" src="https://clouddrove.s3.ca-central-1.amazonaws.com/img/clouddrove-github-cover.png" />
</p>

<h1 align="center">Terraform Cloudflare Zero Trust</h1>
<p align="center"><em>Access applications and policies, Gateway policies, Cloudflared tunnels, device posture, and DLP.</em></p>

<p align="center">
  <a href="https://www.terraform.io"><img src="https://img.shields.io/badge/terraform-%3E%3D%201.10-844FBA?logo=terraform&logoColor=white" alt="Terraform" /></a>
  <a href="https://opentofu.org"><img src="https://img.shields.io/badge/opentofu-%3E%3D%201.9-FFDA18?logo=opentofu&logoColor=black" alt="OpenTofu" /></a>
  <a href="https://registry.terraform.io/providers/cloudflare/cloudflare/latest"><img src="https://img.shields.io/badge/provider-cloudflare%20~%3E%205.24-F38020?logo=cloudflare&logoColor=white" alt="Cloudflare Provider" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License" /></a>
</p>

---

## What this builds

A working Cloudflare Zero Trust posture rather than a pile of disconnected objects: an identity provider, reusable
Access groups and policies, the applications those policies protect, service tokens for machine callers, Secure
Web Gateway rules, Cloudflared tunnels, device posture and DLP.

Registry address: `terraform-cf-modules/zero-trust/cloudflare`.

---

## Quick start

```hcl
module "zero_trust" {
  source  = "terraform-cf-modules/zero-trust/cloudflare"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  identity_providers = {
    otp = { name = "One time PIN", type = "onetimepin", config = {} }
  }

  access_groups = {
    staff = { include = [{ email_domain = { domain = "example.com" } }] }
  }

  access_policies = {
    allow_staff = {
      decision           = "allow"
      session_duration   = "24h"
      include            = []
      include_group_keys = ["staff"]
      require            = [{ auth_method = { auth_method = "mfa" } }]
    }
  }

  access_applications = {
    intranet = {
      name             = "Intranet"
      type             = "self_hosted"
      domain           = "intranet.example.com"
      destinations     = [{ type = "public", uri = "intranet.example.com" }]
      policy_keys      = ["allow_staff"]
      allowed_idp_keys = ["otp"]
    }
  }
}
```

`examples/basic` is that configuration. `examples/complete` turns on every feature.
`examples/tunnel-private-network` covers the tunnel, ingress and private route combination in detail.

---

## Submodules

| Submodule | Manages |
|-----------|---------|
| [`modules/access-app`](modules/access-app) | `cloudflare_zero_trust_access_application`, `cloudflare_zero_trust_access_custom_page` |
| [`modules/access-policy`](modules/access-policy) | `cloudflare_zero_trust_access_policy`, `..._access_group`, `..._access_tag` |
| [`modules/identity`](modules/identity) | `cloudflare_zero_trust_access_identity_provider`, `..._access_mtls_certificate`, `..._access_mtls_hostname_settings` |
| [`modules/service-token`](modules/service-token) | `cloudflare_zero_trust_access_service_token`, `..._access_short_lived_certificate` |
| [`modules/gateway-policy`](modules/gateway-policy) | `cloudflare_zero_trust_gateway_policy`, `..._gateway_settings`, `..._gateway_certificate`, `..._gateway_proxy_endpoint`, `..._gateway_logging`, `cloudflare_zero_trust_list`, `..._dns_location` |
| [`modules/tunnel`](modules/tunnel) | `cloudflare_zero_trust_tunnel_cloudflared`, `..._config`, `..._route`, `..._virtual_network` |
| [`modules/device-posture`](modules/device-posture) | `cloudflare_zero_trust_device_posture_rule`, `..._posture_integration`, `..._device_custom_profile`, `..._device_default_profile`, `..._device_managed_networks`, `..._device_settings` |
| [`modules/dlp`](modules/dlp) | `cloudflare_zero_trust_dlp_custom_profile`, `..._dlp_custom_entry`, `..._dlp_dataset`, `..._dlp_settings` |

Use one directly when you only want that slice:

```hcl
module "gateway" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/gateway-policy"
  version = "~> 0.1"

  account_id = var.account_id
  policies   = { block_malware = { action = "block", filters = ["dns"], traffic = "..." } }
}
```

---

## Reference things by key, not by ID

The hard part of Zero Trust in Terraform is the wiring: an application needs policy IDs, a policy needs group and
service token IDs, a route needs a tunnel ID, none of which exist until after the first apply. This module lets
you name them by map key and resolves the IDs internally.

| Input | Resolves to |
|-------|-------------|
| `access_applications[*].policy_keys` | Access policy IDs |
| `access_applications[*].allowed_idp_keys` | Identity provider IDs |
| `access_applications[*].custom_page_keys` | Access custom page IDs |
| `access_policies[*].include_group_keys` and the exclude and require variants | Access group IDs |
| `access_policies[*].include_service_token_keys` | Service token IDs |
| `access_policies[*].include_login_method_idp_keys` | Identity provider IDs |
| `short_lived_certificates[*].app_key` | Access application ID |
| `tunnel_routes[*].tunnel_key`, `virtual_network_key` | Tunnel and virtual network IDs |
| `dlp_entries[*].profile_key` | DLP profile ID |

Every one of them is checked by a `validation` block, so a typo fails at plan time naming the key you got wrong.

---

## Access rule selectors

`include`, `exclude` and `require` take a list where each element sets exactly one of 26 optional selector keys.
This is the shape that changed most between v4 and v5.

```hcl
include = [
  { email_domain = { domain = "example.com" } },
  { geo = { country_code = "GB" } },
]
require = [{ auth_method = { auth_method = "mfa" } }]
exclude = [{ ip = { ip = "203.0.113.7" } }]
```

Selectors that carry no fields of their own are written as empty objects:

```hcl
include = [{ everyone = {} }]
exclude = [{ any_valid_service_token = {} }]
```

Available selectors: `any_valid_service_token`, `auth_context`, `auth_method`, `azure_ad`, `certificate`,
`cloudflare_account_member`, `common_name`, `device_posture`, `email`, `email_domain`, `email_list`, `everyone`,
`external_evaluation`, `geo`, `github_organization`, `group`, `gsuite`, `ip`, `ip_list`, `linked_app_token`,
`login_method`, `oidc`, `okta`, `saml`, `service_token`, `user_risk_score`.

---

## Per account singletons

`gateway_settings`, `gateway_logging`, `device_settings`, `device_default_profile` and `dlp_settings` exist once
per Cloudflare account. Each defaults to `null` and the resource is not created until you set it, so two stacks
in the same account cannot silently fight over them. Exactly one stack in your organisation should own each.

---

## Secrets

Tunnel secrets, service token client secrets, identity provider client secrets, SCIM secrets and device posture
integration credentials all land in Terraform state. Every output that carries one is marked `sensitive = true`:
`service_token_client_secrets`, `tunnel_secrets`, `tunnel_tokens`, `identity_providers`, `access_applications`.
Treat the state backend as a secret store.

The module never accepts a Cloudflare API token or key as an input. Authentication belongs to the caller's
`provider` block.

---

## Repository layout

```
terraform.tf          provider and version requirements
main.tf               root module, composes the submodules
variables.tf          root module inputs
outputs.tf            root module outputs
locals.tf             key to ID resolution for the root module
modules/<name>/       eight composable building blocks
examples/basic/       minimum viable example
examples/complete/    every optional feature turned on
examples/tunnel-private-network/  tunnel ingress, routes and virtual networks
wrappers/             for_each wrapper for many instances
tests/                native terraform test files
docs/architecture.md  resource map, ordering, provider quirks
```

---

## Local development

```bash
pre-commit install

make fmt        # terraform fmt -recursive
make validate   # init and validate every directory
make lint       # tflint
make docs       # regenerate the terraform-docs blocks
make test       # mocked terraform test, no credentials needed
make security   # trivy, checkov, gitleaks
make ci         # all of the above
```

`make test` runs against `mock_provider`, so it needs no Cloudflare credentials. The live tests in
`tests/integration.tftest.hcl` run only on schedule and manual dispatch, and deliberately avoid every per account
singleton so a test run cannot clobber the shared test account.

---

## CI

Most workflows call the shared
[clouddrove/github-shared-workflows](https://github.com/clouddrove/github-shared-workflows) at `@v2`.

| Workflow | Source | Purpose |
|----------|--------|---------|
| `tf-checks` | shared | init and validate both examples |
| `tflint` | shared | lint |
| `checkov` | shared | policy scan |
| `gitleaks` | shared | secret scan |
| `pr_checks` | shared | Conventional Commit pull request title |
| `auto_assignee` | shared | reviewer assignment |
| `automerge` | shared | auto merge on green |
| `stale_pr` | shared | stale handling |
| `readme` | shared | rebuild README from README.yaml |
| `tag-release` | shared | tag and changelog on merge |
| `opentofu` | local | OpenTofu compatibility |
| `test` | local | `terraform test` with mocked provider |
| `integration` | local | live apply against a test account, scheduled only |

### Required organisation secrets

| Secret | Used by |
|--------|---------|
| `GITHUB` | `tflint`, `tag-release`, `auto_assignee`, `automerge`, `readme` |
| `SLACK_WEBHOOK_TERRAFORM` | `readme` |
| `CLOUDFLARE_API_TOKEN` | `integration` |
| `CLOUDFLARE_TEST_ACCOUNT_ID` | `integration` |
| `CLOUDFLARE_TEST_ZONE_ID` | `integration` |

---

## Inputs and outputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

---

## License

Apache 2.0. See [LICENSE](LICENSE).

Maintained by [CloudDrove](https://clouddrove.com) and [Cloud Wizz](https://github.com/cloud-wizz).
