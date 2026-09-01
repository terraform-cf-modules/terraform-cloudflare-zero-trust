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
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the applications. Set this or zone\_id, not both. | `string` | `null` | no |
| <a name="input_applications"></a> [applications](#input\_applications) | Access applications to create, keyed by a stable identifier.<br/><br/>`policies` attaches reusable policies created by the access-policy submodule. Each element is<br/>`{ id = "<policy id>", precedence = <number> }`. Order of evaluation follows `precedence`.<br/><br/>`saas_app` is only valid when `type` is `saas` or `dash_sso`. `footer_links` and `landing_page_design`<br/>are only valid when `type` is `app_launcher`. | <pre>map(object({<br/>    name             = optional(string)<br/>    type             = optional(string, "self_hosted")<br/>    domain           = optional(string)<br/>    session_duration = optional(string)<br/>    allowed_idps     = optional(set(string))<br/>    tags             = optional(set(string))<br/>    custom_pages     = optional(list(string))<br/><br/>    # Keys of entries in var.custom_pages, resolved to page IDs inside the module<br/>    # so an application can use a page created by this same module instance.<br/>    custom_page_keys                = optional(list(string), [])<br/>    auto_redirect_to_identity       = optional(bool)<br/>    app_launcher_visible            = optional(bool)<br/>    app_launcher_logo_url           = optional(string)<br/>    bg_color                        = optional(string)<br/>    header_bg_color                 = optional(string)<br/>    logo_url                        = optional(string)<br/>    custom_deny_message             = optional(string)<br/>    custom_deny_url                 = optional(string)<br/>    custom_non_identity_deny_url    = optional(string)<br/>    enable_binding_cookie           = optional(bool)<br/>    http_only_cookie_attribute      = optional(bool)<br/>    path_cookie_attribute           = optional(bool)<br/>    same_site_cookie_attribute      = optional(string)<br/>    options_preflight_bypass        = optional(bool)<br/>    service_auth_401_redirect       = optional(bool)<br/>    skip_interstitial               = optional(bool)<br/>    skip_app_launcher_login_page    = optional(bool)<br/>    allow_authenticate_via_warp     = optional(bool)<br/>    allow_iframe                    = optional(bool)<br/>    read_service_tokens_from_header = optional(string)<br/><br/>    policies = optional(list(object({<br/>      id         = string<br/>      precedence = optional(number)<br/>    })), [])<br/><br/>    cors_headers = optional(object({<br/>      allow_all_headers = optional(bool)<br/>      allow_all_methods = optional(bool)<br/>      allow_all_origins = optional(bool)<br/>      allow_credentials = optional(bool)<br/>      allowed_headers   = optional(set(string))<br/>      allowed_methods   = optional(set(string))<br/>      allowed_origins   = optional(set(string))<br/>      max_age           = optional(number)<br/>    }))<br/><br/>    destinations = optional(list(object({<br/>      type          = optional(string)<br/>      uri           = optional(string)<br/>      hostname      = optional(string)<br/>      cidr          = optional(string)<br/>      l4_protocol   = optional(string)<br/>      port_range    = optional(string)<br/>      vnet_id       = optional(string)<br/>      worker_id     = optional(string)<br/>      mcp_server_id = optional(string)<br/>    })))<br/><br/>    footer_links = optional(list(object({<br/>      name = string<br/>      url  = string<br/>    })))<br/><br/>    landing_page_design = optional(object({<br/>      button_color      = optional(string)<br/>      button_text_color = optional(string)<br/>      image_url         = optional(string)<br/>      message           = optional(string)<br/>      title             = optional(string)<br/>    }))<br/><br/>    mfa_config = optional(object({<br/>      allowed_authenticators = optional(list(string))<br/>      mfa_disabled           = optional(bool)<br/>      session_duration       = optional(string)<br/>    }))<br/><br/>    oauth_configuration = optional(object({<br/>      enabled = optional(bool)<br/>      dynamic_client_registration = optional(object({<br/>        allow_any_on_localhost = optional(bool)<br/>        allow_any_on_loopback  = optional(bool)<br/>        allowed_uris           = optional(list(string))<br/>        enabled                = optional(bool)<br/>      }))<br/>      grant = optional(object({<br/>        access_token_lifetime = optional(string)<br/>        session_duration      = optional(string)<br/>      }))<br/>    }))<br/><br/>    target_criteria = optional(list(object({<br/>      port              = number<br/>      protocol          = string<br/>      target_attributes = map(list(string))<br/>    })))<br/><br/>    scim_config = optional(object({<br/>      idp_uid              = string<br/>      remote_uri           = string<br/>      enabled              = optional(bool)<br/>      deactivate_on_delete = optional(bool)<br/>      authentication = optional(object({<br/>        scheme            = string<br/>        authorization_url = optional(string)<br/>        client_id         = optional(string)<br/>        client_secret     = optional(string)<br/>        password          = optional(string)<br/>        scopes            = optional(list(string))<br/>        token             = optional(string)<br/>        token_url         = optional(string)<br/>        user              = optional(string)<br/>      }))<br/>      mappings = optional(list(object({<br/>        schema            = string<br/>        enabled           = optional(bool)<br/>        filter            = optional(string)<br/>        strictness        = optional(string)<br/>        transform_jsonata = optional(string)<br/>        operations = optional(object({<br/>          create = optional(bool)<br/>          delete = optional(bool)<br/>          update = optional(bool)<br/>        }))<br/>      })))<br/>    }))<br/><br/>    saas_app = optional(object({<br/>      auth_type                        = optional(string)<br/>      access_token_lifetime            = optional(string)<br/>      allow_pkce_without_client_secret = optional(bool)<br/>      app_launcher_url                 = optional(string)<br/>      consumer_service_url             = optional(string)<br/>      default_relay_state              = optional(string)<br/>      grant_types                      = optional(list(string))<br/>      group_filter_regex               = optional(string)<br/>      idp_entity_id                    = optional(string)<br/>      name_id_format                   = optional(string)<br/>      name_id_transform_jsonata        = optional(string)<br/>      redirect_uris                    = optional(list(string))<br/>      saml_attribute_transform_jsonata = optional(string)<br/>      scopes                           = optional(list(string))<br/>      sp_entity_id                     = optional(string)<br/>      sso_endpoint                     = optional(string)<br/>      hybrid_and_implicit_options = optional(object({<br/>        return_access_token_from_authorization_endpoint = optional(bool)<br/>        return_id_token_from_authorization_endpoint     = optional(bool)<br/>      }))<br/>      refresh_token_options = optional(object({<br/>        lifetime = optional(string)<br/>      }))<br/>      custom_attributes = optional(list(object({<br/>        friendly_name = optional(string)<br/>        name          = optional(string)<br/>        name_format   = optional(string)<br/>        required      = optional(bool)<br/>        source = optional(object({<br/>          name = optional(string)<br/>          name_by_idp = optional(list(object({<br/>            idp_id      = optional(string)<br/>            source_name = optional(string)<br/>          })))<br/>        }))<br/>      })))<br/>      custom_claims = optional(list(object({<br/>        name     = optional(string)<br/>        required = optional(bool)<br/>        scope    = optional(string)<br/>        source = optional(object({<br/>          name        = optional(string)<br/>          name_by_idp = optional(map(string))<br/>        }))<br/>      })))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_custom_pages"></a> [custom\_pages](#input\_custom\_pages) | Access custom pages to create, keyed by a stable identifier. Reference them from an application through its custom\_pages list. | <pre>map(object({<br/>    name             = optional(string)<br/>    type             = string<br/>    custom_html      = string<br/>    contract_version = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Cloudflare zone ID that owns the applications. Set this or account\_id, not both. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_application_auds"></a> [application\_auds](#output\_application\_auds) | Map of application key to the application audience (AUD) tag, used to validate Access JWTs. |
| <a name="output_application_domains"></a> [application\_domains](#output\_application\_domains) | Map of application key to the primary domain the application protects. |
| <a name="output_application_ids"></a> [application\_ids](#output\_application\_ids) | Map of application key to application ID. |
| <a name="output_applications"></a> [applications](#output\_applications) | Full Access application objects, keyed by the same keys as var.applications. |
| <a name="output_custom_page_ids"></a> [custom\_page\_ids](#output\_custom\_page\_ids) | Map of custom page key to page ID. |
| <a name="output_custom_pages"></a> [custom\_pages](#output\_custom\_pages) | Full Access custom page objects, keyed by the same keys as var.custom\_pages. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
<!-- END_TF_DOCS -->
