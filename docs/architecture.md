# Architecture

This module builds a Cloudflare Zero Trust posture: who your users are, which applications they can reach, what
they may do on the internet, how private networks are exposed, what a device must prove, and what data may leave.

The root module composes eight building blocks. Each block is publishable on its own, so a team that only wants
Gateway rules does not have to adopt the whole thing.

```
   identity                          service-token (first call)
   identity providers, mTLS          service tokens
        |                                   |
        | provider IDs                      | token IDs
        +-----------------+-----------------+
                          v
                    access-policy
                    groups, policies, tags
                          |
                          | policy IDs
                          v
                     access-app
                     applications, custom pages
                          |
                          | application IDs
                          v
                    service-token (second call)
                    short lived SSH certificates

   no cross dependencies:  gateway-policy   tunnel   device-posture   dlp
```

## Resource map

| Terraform resource | Cloudflare object | Created by |
|--------------------|-------------------|------------|
| `cloudflare_zero_trust_access_application` | Access application | `modules/access-app` |
| `cloudflare_zero_trust_access_custom_page` | Access custom page | `modules/access-app` |
| `cloudflare_zero_trust_access_policy` | Reusable Access policy | `modules/access-policy` |
| `cloudflare_zero_trust_access_group` | Access group | `modules/access-policy` |
| `cloudflare_zero_trust_access_tag` | Access tag | `modules/access-policy` |
| `cloudflare_zero_trust_access_identity_provider` | Identity provider | `modules/identity` |
| `cloudflare_zero_trust_access_mtls_certificate` | mTLS root CA | `modules/identity` |
| `cloudflare_zero_trust_access_mtls_hostname_settings` | Per hostname mTLS settings | `modules/identity` |
| `cloudflare_zero_trust_access_service_token` | Service token | `modules/service-token` |
| `cloudflare_zero_trust_access_short_lived_certificate` | SSH certificate authority | `modules/service-token` |
| `cloudflare_zero_trust_gateway_policy` | Gateway rule | `modules/gateway-policy` |
| `cloudflare_zero_trust_gateway_settings` | Account Gateway settings | `modules/gateway-policy` |
| `cloudflare_zero_trust_gateway_certificate` | Inspection certificate | `modules/gateway-policy` |
| `cloudflare_zero_trust_gateway_proxy_endpoint` | Explicit proxy endpoint | `modules/gateway-policy` |
| `cloudflare_zero_trust_gateway_logging` | Gateway log settings | `modules/gateway-policy` |
| `cloudflare_zero_trust_list` | Zero Trust list | `modules/gateway-policy` |
| `cloudflare_zero_trust_dns_location` | Gateway DNS location | `modules/gateway-policy` |
| `cloudflare_zero_trust_tunnel_cloudflared` | Cloudflared tunnel | `modules/tunnel` |
| `cloudflare_zero_trust_tunnel_cloudflared_config` | Remote tunnel configuration | `modules/tunnel` |
| `cloudflare_zero_trust_tunnel_cloudflared_route` | Private network route | `modules/tunnel` |
| `cloudflare_zero_trust_tunnel_cloudflared_virtual_network` | Tunnel virtual network | `modules/tunnel` |
| `cloudflare_zero_trust_device_posture_rule` | Device posture rule | `modules/device-posture` |
| `cloudflare_zero_trust_device_posture_integration` | MDM or EDR integration | `modules/device-posture` |
| `cloudflare_zero_trust_device_custom_profile` | WARP profile | `modules/device-posture` |
| `cloudflare_zero_trust_device_default_profile` | Default WARP profile | `modules/device-posture` |
| `cloudflare_zero_trust_device_managed_networks` | Managed network | `modules/device-posture` |
| `cloudflare_zero_trust_device_settings` | Account device settings | `modules/device-posture` |
| `cloudflare_zero_trust_dlp_custom_profile` | DLP profile | `modules/dlp` |
| `cloudflare_zero_trust_dlp_custom_entry` | DLP detection | `modules/dlp` |
| `cloudflare_zero_trust_dlp_dataset` | DLP dataset | `modules/dlp` |
| `cloudflare_zero_trust_dlp_settings` | Account DLP settings | `modules/dlp` |

## Scope

Almost everything here is **account scoped** and anchored by `account_id`. Only five Access resources also
accept `zone_id`: applications, groups, identity providers, mTLS certificates and service tokens. Gateway,
tunnels, device posture and DLP are account only, and `cloudflare_zero_trust_access_policy` is account only
even though the group resource beside it is not.

Set one anchor or the other on the zone scoped resources, never both.

## Ordering and dependencies

Terraform derives most of the ordering from references, but three edges are worth knowing.

1. **Policies before applications.** In provider v5 a policy is a standalone object with no `application_id`,
   and the application lists the policy IDs it uses. The root module resolves `policy_keys` into IDs, which
   creates the dependency implicitly. There is no `depends_on` anywhere in this module.

2. **The service-token submodule is called twice.** Access policies reference service tokens, applications
   reference policies, and short lived certificates reference applications. Creating tokens and SSH CAs in one
   module call would make `module.service_token` depend on `module.access_app` and back again, which Terraform
   rejects as a module level cycle. The root module therefore calls `modules/service-token` once for tokens
   before the policies, and once again for short lived certificates after the applications exist.

3. **Groups referenced from policies in the same module call.** A policy cannot read
   `module.<self>.access_group_ids` from inside its own module block. `access-policy` exposes
   `include_group_keys`, `exclude_group_keys` and `require_group_keys` so the resolution happens inside the
   module, where it is a resource to resource edge rather than a module to module one.

The root module applies the same idea to every cross submodule reference: callers name things by key, never by
an ID that does not exist until after the first apply. `policy_keys`, `allowed_idp_keys`, `custom_page_keys`,
`include_service_token_keys`, `include_login_method_idp_keys`, `app_key`, `tunnel_key`, `virtual_network_key`
and `profile_key` all work this way, and each is checked by a `validation` block that fails fast when the key
does not exist.

## Per account singletons

Five objects exist once per Cloudflare account rather than as collections:

| Input | Resource |
|-------|----------|
| `gateway_settings` | `cloudflare_zero_trust_gateway_settings` |
| `gateway_logging` | `cloudflare_zero_trust_gateway_logging` |
| `device_settings` | `cloudflare_zero_trust_device_settings` |
| `device_default_profile` | `cloudflare_zero_trust_device_default_profile` |
| `dlp_settings` | `cloudflare_zero_trust_dlp_settings` |

Each defaults to `null` and the resource is not created at all until you set it. That is deliberate: if two
stacks in the same account both managed one of these, every apply would fight the other. Exactly one stack in
your organisation should own each. `mtls_hostname_settings` behaves the same way but is a list, because the API
stores one settings document holding every hostname.

## Known provider quirks

**Everything was renamed in v5.** `cloudflare_access_application` is now
`cloudflare_zero_trust_access_application`, `cloudflare_teams_rule` is now
`cloudflare_zero_trust_gateway_policy`, `cloudflare_tunnel` is now
`cloudflare_zero_trust_tunnel_cloudflared`, and `cloudflare_dlp_profile` is now
`cloudflare_zero_trust_dlp_custom_profile`. Every submodule README carries the old name beside the new one.

**Blocks became object attributes.** `config`, `input`, `rule_settings`, `include` and friends were repeatable
blocks in v4 and are attributes in v5. Write `config = { ... }`, not `config { ... }`. Every collection input
in this module is a map or a list of objects for that reason.

**Access rule selectors are a wide optional object.** `include`, `exclude` and `require` take a list where each
element sets exactly one of 26 optional keys. Selectors with no fields of their own are empty objects:
`{ everyone = {} }`, `{ certificate = {} }`, `{ any_valid_service_token = {} }`.

**The provider enforces attribute combinations.** An Access application rejects `saas_app` unless its type is
`saas` or `dash_sso`, rejects `footer_links` and `landing_page_design` unless the type is `app_launcher`,
rejects `app_launcher_visible` when the type *is* `app_launcher`, and rejects `cors_headers` unless exactly one
of `allow_all_origins` or `allowed_origins` is set. This module reproduces those rules as `validation` blocks so
the failure arrives at plan time with a readable message rather than from the provider mid apply.

**Deprecations in 5.24 that this module routes around.**

| Deprecated | Used instead |
|------------|--------------|
| `cloudflare_zero_trust_access_application.self_hosted_domains` | `destinations` |
| `cloudflare_zero_trust_tunnel_cloudflared_virtual_network.is_default` | `is_default_network` |
| `cloudflare_zero_trust_dlp_custom_profile.entries` (sunset 01/01/2026) | `cloudflare_zero_trust_dlp_custom_entry`, still exposed as `entries` for now and left null when empty |
| `cloudflare_zero_trust_dlp_custom_profile.context_awareness` | not exposed |

`self_hosted_domains` is computed as well as deprecated, so reading the whole application object still emits a
deprecation warning from the provider. That warning comes from the `access_applications` output, not from
anything this module sets.

**Ingress rules are ordered and need a catch all.** `cloudflare_zero_trust_tunnel_cloudflared_config` takes an
ordered `ingress` list; the first matching rule wins and the last rule must have no hostname. Two `validation`
blocks on `var.tunnels` enforce both properties before the provider sees the plan.

**Secrets in state.** Tunnel secrets, service token client secrets, identity provider client secrets, SCIM
secrets and device posture integration credentials all land in Terraform state. Every output carrying one is
marked `sensitive = true`. Treat the state backend as a secret store.
