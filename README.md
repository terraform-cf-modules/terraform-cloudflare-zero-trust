<!-- This file was automatically generated from `README.yaml`. Make all changes to `README.yaml` and run `make readme` to rebuild this file. -->
<p align="center">
  <img width="1024" height="250" alt="CloudDrove" src="https://clouddrove.s3.ca-central-1.amazonaws.com/Logo/banner.png" />
</p>
<h1 align="center">
    Terraform Cloudflare Zero Trust
</h1>

<p align="center" style="font-size: 1.2rem;">
    With our comprehensive DevOps toolkit, streamline operations, automate workflows, enhance collaboration and deploy with confidence.
</p>

<p align="center">

<a href="https://www.terraform.io">
  <img src="https://img.shields.io/badge/Terraform-v1.12.0-green" alt="Terraform">
</a>
<a href="LICENSE">
  <img src="https://img.shields.io/badge/License-APACHE-blue.svg" alt="Licence">
</a>
<a href="CHANGELOG.md">
  <img src="https://img.shields.io/badge/Changelog-blue" alt="Changelog">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/tf-checks.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/tf-checks.yml/badge.svg" alt="tf-checks">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/tflint.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/tflint.yml/badge.svg" alt="tf-lint">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/checkov.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/checkov.yml/badge.svg" alt="checkov">
</a>
<a href="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/test.yml">
  <img src="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/actions/workflows/test.yml/badge.svg" alt="test">
</a>

</p>
<hr>


Terraform module for Cloudflare Zero Trust. It builds a working posture rather than a pile of disconnected
objects: an identity provider, reusable Access groups and policies, the applications those policies protect,
service tokens for machine callers, Secure Web Gateway rules, Cloudflared tunnels, device posture and Data
Loss Prevention. The root module composes the common case, and the eight submodules under `modules/` are
each usable on their own.

The opinion this module encodes is that you should never have to hard code an ID. The hard part of Zero
Trust in Terraform is the wiring: an application needs policy IDs, a policy needs group and service token
IDs, a route needs a tunnel ID, and none of those exist until after the first apply. Here you name things by
map key and the module resolves the IDs internally, with a `validation` block behind every key so a typo
fails at plan time naming the key you got wrong.

Key resolution alone is not enough, because the references form a loop at the module level. Service tokens
must exist before Access policies can reference them, policies must exist before applications can attach
them, and short lived SSH certificates need an application ID. Terraform rejects that as a module cycle if
the resources sit in one call. The root module therefore calls `modules/service-token` twice, once for the
tokens before the policies and once again for the short lived certificates after the applications exist.
Ordinary attribute references then carry the dependency, so there is no `depends_on` anywhere in this module.

Every resource targets Cloudflare provider v5. Cloudflare regenerated the provider from its OpenAPI spec in
v5.0.0 and renamed almost everything in this product area, so `cloudflare_access_application` is now
`cloudflare_zero_trust_access_application` and `cloudflare_teams_rule` is now
`cloudflare_zero_trust_gateway_policy`. See [`docs/architecture.md`](docs/architecture.md) for the full
rename table, the resource map and the provider quirks this module works around.

### Reference things by key, not by ID

| Input | Resolves to |
|-------|-------------|
| `access_applications[*].policy_keys` | Access policy IDs |
| `access_applications[*].allowed_idp_keys` | Identity provider IDs |
| `access_applications[*].custom_page_keys` | Access custom page IDs |
| `access_policies[*].include_group_keys`, and the exclude and require variants | Access group IDs |
| `access_policies[*].include_service_token_keys` | Service token IDs |
| `access_policies[*].include_login_method_idp_keys` | Identity provider IDs |
| `short_lived_certificates[*].app_key` | Access application ID |
| `tunnel_routes[*].tunnel_key` and `virtual_network_key` | Tunnel and virtual network IDs |
| `dlp_entries[*].profile_key` | DLP profile ID |

### Access rule selectors

`include`, `exclude` and `require` take a list where each element sets exactly one of 26 optional selector
keys. This is the shape that changed most between provider v4 and v5.

```hcl
include = [
  { email_domain = { domain = "example.com" } },
  { geo          = { country_code = "GB" } },
]
require = [{ auth_method = { auth_method = "mfa" } }]
exclude = [{ ip = { ip = "203.0.113.7" } }]
```

Selectors that carry no fields of their own are written as empty objects, for example `{ everyone = {} }` or
`{ any_valid_service_token = {} }`. The full set is `any_valid_service_token`, `auth_context`, `auth_method`,
`azure_ad`, `certificate`, `cloudflare_account_member`, `common_name`, `device_posture`, `email`,
`email_domain`, `email_list`, `everyone`, `external_evaluation`, `geo`, `github_organization`, `group`,
`gsuite`, `ip`, `ip_list`, `linked_app_token`, `login_method`, `oidc`, `okta`, `saml`, `service_token` and
`user_risk_score`.

### Per account singletons

`gateway_settings`, `gateway_logging`, `device_settings`, `device_default_profile` and `dlp_settings` exist
once per Cloudflare account. Each defaults to `null` and the resource is not created until you set it, so
two stacks in the same account cannot silently fight over them. Exactly one stack in your organisation
should own each.

### Secrets

Tunnel secrets, service token client secrets, identity provider client secrets, SCIM secrets and device
posture integration credentials all land in Terraform state. Every output that carries one is marked
`sensitive = true`, namely `service_token_client_secrets`, `tunnel_secrets`, `tunnel_tokens`,
`identity_providers` and `access_applications`. Treat the state backend as a secret store. The module never
accepts a Cloudflare API token or key as an input; authentication belongs to the caller's `provider` block.


## Prerequisites and Providers

This table contains both Prerequisites and Providers:

| Description | Name | Version |
|-------------|------|---------|
| Prerequisite | Terraform | >= 1.12.0 |
| Prerequisite | OpenTofu | >= 1.12.0 |
| Provider | cloudflare | ~> 5.24 |

---


## 🧩 Submodules

Each submodule is separately addressable with the double slash source syntax, so you can take only the piece you need instead of the whole root module.

| Submodule | Source | Description |
|-----------|--------|-------------|
| [`access-app`](modules/access-app) | `terraform-cf-modules/zero-trust/cloudflare//modules/access-app` | Access applications and the custom block pages they present (`cloudflare_zero_trust_access_application`, `cloudflare_zero_trust_access_custom_page`). |
| [`access-policy`](modules/access-policy) | `terraform-cf-modules/zero-trust/cloudflare//modules/access-policy` | Reusable Access policies, groups and tags, attachable to any number of applications. |
| [`identity`](modules/identity) | `terraform-cf-modules/zero-trust/cloudflare//modules/identity` | Identity providers, mTLS certificates and mTLS hostname settings. |
| [`service-token`](modules/service-token) | `terraform-cf-modules/zero-trust/cloudflare//modules/service-token` | Service tokens for machine to machine callers, and short lived SSH certificate issuers. |
| [`gateway-policy`](modules/gateway-policy) | `terraform-cf-modules/zero-trust/cloudflare//modules/gateway-policy` | Secure Web Gateway rules plus gateway settings, logging, certificates, proxy endpoints, lists and DNS locations. |
| [`tunnel`](modules/tunnel) | `terraform-cf-modules/zero-trust/cloudflare//modules/tunnel` | Cloudflared tunnels, their ingress configuration, private network routes and virtual networks. |
| [`device-posture`](modules/device-posture) | `terraform-cf-modules/zero-trust/cloudflare//modules/device-posture` | Device posture rules and integrations, WARP device profiles, managed networks and device settings. |
| [`dlp`](modules/dlp) | `terraform-cf-modules/zero-trust/cloudflare//modules/dlp` | Data Loss Prevention profiles, custom entries, datasets and account level DLP settings. |

---


## 🚀 Usage

### Root module

An identity provider, a group, a policy and the application the policy protects. This is
[`examples/basic`](examples/basic); [`examples/complete`](examples/complete) turns on every feature.

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

### Gateway rules on their own

Take one submodule when you only want that slice. Lower `precedence` runs first, and `traffic` is a
Wirefilter expression.

```hcl
module "gateway" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/gateway-policy"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  policies = {
    block_security_risks = {
      name       = "Block security risks"
      action     = "block"
      filters    = ["dns"]
      precedence = 100
      traffic    = "any(dns.security_category[*] in {80 83 117 131})"
    }

    isolate_uncategorised = {
      name       = "Isolate uncategorised sites"
      action     = "isolate"
      filters    = ["http"]
      precedence = 200
      traffic    = "any(http.request.uri.content_category[*] in {155})"
    }
  }
}
```

### A tunnel and the private network behind it

Routes point at a tunnel by `tunnel_key` and at a virtual network by `virtual_network_key`, both created in
the same call. The final ingress rule must be a catch all with no hostname. See
[`examples/tunnel-private-network`](examples/tunnel-private-network) for the longer version.

```hcl
module "tunnel" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/tunnel"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  virtual_networks = {
    prod = { name = "prod", comment = "Production private network" }
  }

  tunnels = {
    prod = {
      name       = "prod-egress"
      config_src = "cloudflare"

      config = {
        ingress = [
          { hostname = "app.example.com", service = "http://10.0.1.10:8080" },
          { service = "http_status:404" },
        ]
      }
    }
  }

  routes = {
    prod_vpc = {
      network             = "10.0.0.0/16"
      comment             = "Production VPC"
      tunnel_key          = "prod"
      virtual_network_key = "prod"
    }
  }
}
```

A `wrappers/` module is also published for callers that need many instances of the root module driven by one
`for_each` over a `defaults` and `items` pair.

---


## 📦 Examples

> ⚠️ **Important:** Avoid using the `main` branch directly, as it may include unstable changes. Always use stable [release versions](https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/releases).

Explore real-world usage scenarios and implementation patterns in the [`examples/`](./examples/) directory.

---


## 📥 Inputs and Outputs

Detailed input variables and output values are documented for easier integration and day-to-day usage.

📘 [View full documentation](docs/io.md)

---


## 📝 Changelog

Track module updates, improvements, and breaking changes across versions.

📌 [View Changelog](CHANGELOG.md)

---


## ✨ Contributors

Big thanks to our contributors for elevating our project with their dedication and expertise!

<div align="center">
  <a href="https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/graphs/contributors" title="Contributors">
    <img src="https://contrib.rocks/image?repo=terraform-cf-modules/terraform-cloudflare-zero-trust" />
  </a>
</div>

All contributors must follow the [Conventional Commits](https://www.conventionalcommits.org) specification for commit messages.

---


## 🚀 Our Accomplishment

We maintain Terraform modules across AWS, Azure, Google Cloud, DigitalOcean, Hetzner Cloud and Cloudflare 🙌.

- [**Terraform Module Registry**](https://registry.terraform.io/namespaces/terraform-cf-modules): Discover our Cloudflare modules here.
- [**Full module catalog**](https://github.com/clouddrove/toc): Every CloudDrove module and submodule, across every cloud.

---

## Notes

- Do not use the `main` branch for production deployments.
- Always reference a stable version using Git tags or official releases.
- Using tagged versions ensures consistency, stability, and reproducible deployments.

---

## Feedback

Report issues or request features on [GitHub](https://github.com/terraform-cf-modules/terraform-cloudflare-zero-trust/issues), or write to [business@clouddrove.com](mailto:business@clouddrove.com).

## About us

At [CloudDrove](https://clouddrove.com), we build reliable, secure and cost efficient cloud native solutions. Join our [Slack community](https://www.launchpass.com/devops-talks).
