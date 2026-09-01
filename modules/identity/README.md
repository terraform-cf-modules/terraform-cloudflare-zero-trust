# Submodule: identity

Access identity providers and mutual TLS material.

| Terraform resource | Purpose |
|--------------------|---------|
| `cloudflare_zero_trust_access_identity_provider` | SSO connector, one per IdP |
| `cloudflare_zero_trust_access_mtls_certificate` | Client certificate root CA |
| `cloudflare_zero_trust_access_mtls_hostname_settings` | Per hostname mTLS behaviour |

## v4 to v5

`config` was a repeatable block in v4. In v5 it is a single flat object, so write `config = { ... }` rather than
`config { ... }`. The fields that matter depend on `type`.

`cloudflare_access_mutual_tls_certificate` is now `cloudflare_zero_trust_access_mtls_certificate`.

## Secrets

`config.client_secret` is stored in Terraform state. Supply it from a secret store or a variable sourced from the
environment, never as a literal in version control. The provider marks it sensitive so it is redacted in plan
output, and the `identity_providers` output of this module is marked sensitive for the same reason.

## mTLS hostname settings is a singleton

Cloudflare stores one settings document per account or zone, so `var.mtls_hostname_settings` is a list and every
apply replaces the whole document. It must list every hostname you manage, not just the one you are changing.
Leave it empty and the resource is not created at all.

## Usage

```hcl
module "identity" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/identity"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  identity_providers = {
    otp = {
      name   = "One time PIN"
      type   = "onetimepin"
      config = {}
    }

    okta = {
      type = "okta"
      config = {
        client_id     = var.okta_client_id
        client_secret = var.okta_client_secret
        okta_account  = "https://example.okta.com"
      }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the identity providers and mTLS certificates. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_identity_providers"></a> [identity\_providers](#input\_identity\_providers) | Access identity providers, keyed by a stable identifier.<br/><br/>`config` is a single flat object in provider v5. Which fields matter depends on `type`: OIDC style providers<br/>use client\_id, client\_secret, auth\_url, token\_url, certs\_url and scopes, SAML uses issuer\_url, sso\_target\_url,<br/>idp\_public\_certs and attributes, and `onetimepin` needs an empty config object.<br/><br/>Provider secrets are written into Terraform state. Supply them from a secret store, never as a literal. | <pre>map(object({<br/>    name                    = optional(string)<br/>    type                    = string<br/>    read_only               = optional(bool)<br/>    saml_certificate_set_id = optional(string)<br/><br/>    config = object({<br/>      apps_domain                 = optional(string)<br/>      attributes                  = optional(list(string))<br/>      auth_url                    = optional(string)<br/>      authorization_server_id     = optional(string)<br/>      centrify_account            = optional(string)<br/>      centrify_app_id             = optional(string)<br/>      certs_url                   = optional(string)<br/>      claims                      = optional(list(string))<br/>      client_id                   = optional(string)<br/>      client_secret               = optional(string)<br/>      conditional_access_enabled  = optional(bool)<br/>      directory_id                = optional(string)<br/>      email_attribute_name        = optional(string)<br/>      email_claim_name            = optional(string)<br/>      enable_encryption           = optional(bool)<br/>      idp_public_certs            = optional(list(string))<br/>      issuer_url                  = optional(string)<br/>      okta_account                = optional(string)<br/>      onelogin_account            = optional(string)<br/>      ping_env_id                 = optional(string)<br/>      pkce_enabled                = optional(bool)<br/>      prompt                      = optional(string)<br/>      restrict_to_account_members = optional(bool)<br/>      scopes                      = optional(list(string))<br/>      sign_request                = optional(bool)<br/>      sso_target_url              = optional(string)<br/>      support_groups              = optional(bool)<br/>      token_url                   = optional(string)<br/>      header_attributes = optional(list(object({<br/>        attribute_name = optional(string)<br/>        header_name    = optional(string)<br/>      })))<br/>    })<br/><br/>    scim_config = optional(object({<br/>      enabled                  = optional(bool)<br/>      identity_update_behavior = optional(string)<br/>      seat_deprovision         = optional(bool)<br/>      user_deprovision         = optional(bool)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_mtls_certificates"></a> [mtls\_certificates](#input\_mtls\_certificates) | Access mTLS root certificates, keyed by a stable identifier. `certificate` is the PEM encoded CA certificate. | <pre>map(object({<br/>    name                 = optional(string)<br/>    certificate          = string<br/>    associated_hostnames = optional(set(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_mtls_hostname_settings"></a> [mtls\_hostname\_settings](#input\_mtls\_hostname\_settings) | Per hostname mTLS behaviour. The Cloudflare API models this as one settings object per scope, so this is a list rather than a map. Leave empty to manage nothing. | <pre>list(object({<br/>    hostname                      = string<br/>    china_network                 = bool<br/>    client_certificate_forwarding = bool<br/>  }))</pre> | `[]` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID, for zone scoped identity providers and mTLS certificates. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_identity_provider_ids"></a> [identity\_provider\_ids](#output\_identity\_provider\_ids) | Map of identity provider key to provider ID. Use these in an application's allowed\_idps or in an Access policy selector. |
| <a name="output_identity_provider_scim_base_urls"></a> [identity\_provider\_scim\_base\_urls](#output\_identity\_provider\_scim\_base\_urls) | Map of identity provider key to the SCIM base URL, empty when SCIM is not enabled. |
| <a name="output_identity_providers"></a> [identity\_providers](#output\_identity\_providers) | Full identity provider objects. Marked sensitive because config carries the OAuth client secret and scim\_config carries the SCIM secret. |
| <a name="output_mtls_certificate_ids"></a> [mtls\_certificate\_ids](#output\_mtls\_certificate\_ids) | Map of mTLS certificate key to certificate ID. |
| <a name="output_mtls_certificates"></a> [mtls\_certificates](#output\_mtls\_certificates) | Full mTLS certificate objects, keyed by the same keys as var.mtls\_certificates. |
| <a name="output_mtls_hostname_settings"></a> [mtls\_hostname\_settings](#output\_mtls\_hostname\_settings) | The mTLS hostname settings object, or null when none are managed. |
<!-- END_TF_DOCS -->
