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
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the service tokens. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_service_tokens"></a> [service\_tokens](#input\_service\_tokens) | Access service tokens for machine to machine authentication, keyed by a stable identifier.<br/><br/>`duration` is the token lifetime, for example `8760h`. Bump `client_secret_version` to rotate the secret;<br/>`previous_client_secret_expires_at` sets how long the old secret keeps working during the rotation. | <pre>map(object({<br/>    name                              = optional(string)<br/>    duration                          = optional(string)<br/>    enabled                           = optional(bool)<br/>    client_secret_version             = optional(number)<br/>    previous_client_secret_expires_at = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_short_lived_certificates"></a> [short\_lived\_certificates](#input\_short\_lived\_certificates) | Short lived certificate (SSH CA) issuers, keyed by a stable identifier. `app_id` is the ID of the Access application to issue certificates for. | <pre>map(object({<br/>    app_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID, for zone scoped service tokens. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_service_token_client_ids"></a> [service\_token\_client\_ids](#output\_service\_token\_client\_ids) | Map of service token key to client ID. Sent as the CF-Access-Client-Id header. |
| <a name="output_service_token_client_secrets"></a> [service\_token\_client\_secrets](#output\_service\_token\_client\_secrets) | Map of service token key to client secret. Sent as the CF-Access-Client-Secret header. Returned by the API on creation only. |
| <a name="output_service_token_expires_at"></a> [service\_token\_expires\_at](#output\_service\_token\_expires\_at) | Map of service token key to expiry timestamp. |
| <a name="output_service_token_ids"></a> [service\_token\_ids](#output\_service\_token\_ids) | Map of service token key to token ID. Use these in an Access policy service\_token selector. |
| <a name="output_service_tokens"></a> [service\_tokens](#output\_service\_tokens) | Full service token objects. Marked sensitive because each carries client\_secret. |
| <a name="output_short_lived_certificate_ids"></a> [short\_lived\_certificate\_ids](#output\_short\_lived\_certificate\_ids) | Map of short lived certificate key to certificate ID. |
| <a name="output_short_lived_certificate_public_keys"></a> [short\_lived\_certificate\_public\_keys](#output\_short\_lived\_certificate\_public\_keys) | Map of short lived certificate key to the SSH CA public key. Install this on the target hosts as a TrustedUserCAKeys entry. |
| <a name="output_short_lived_certificates"></a> [short\_lived\_certificates](#output\_short\_lived\_certificates) | Full short lived certificate objects, keyed by the same keys as var.short\_lived\_certificates. |
<!-- END_TF_DOCS -->
