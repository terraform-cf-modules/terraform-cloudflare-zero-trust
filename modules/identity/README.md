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
<!-- END_TF_DOCS -->
