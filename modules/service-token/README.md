# Submodule: service-token

Machine to machine credentials for Access.

| Terraform resource | Purpose |
|--------------------|---------|
| `cloudflare_zero_trust_access_service_token` | Client ID and secret pair for non human callers |
| `cloudflare_zero_trust_access_short_lived_certificate` | SSH CA that signs short lived user certificates |

## Secrets

`client_secret` is returned by the Cloudflare API only when the token is created. It lands in Terraform state,
so treat state as a secret. `service_token_client_secrets` and `service_tokens` are marked `sensitive = true`.

To rotate without downtime, increment `client_secret_version` and set `previous_client_secret_expires_at` to the
point where the old secret should stop working.

## Using a token in a policy

```hcl
access_policies = {
  ci = {
    decision = "non_identity"
    include  = [{ service_token = { token_id = module.tokens.service_token_ids.ci } }]
  }
}
```

`{ any_valid_service_token = {} }` accepts any token in the account instead of a named one.

## Usage

```hcl
module "tokens" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/service-token"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  service_tokens = {
    ci = {
      name     = "ci-pipeline"
      duration = "8760h"
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
