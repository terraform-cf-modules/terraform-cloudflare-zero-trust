# Submodule: gateway-policy

Secure Web Gateway rules and the account wide configuration they run under.

| Terraform resource | v4 name | Purpose |
|--------------------|---------|---------|
| `cloudflare_zero_trust_gateway_policy` | `cloudflare_teams_rule` | DNS, HTTP, network and egress rules |
| `cloudflare_zero_trust_gateway_settings` | `cloudflare_teams_account` | Account wide Gateway configuration |
| `cloudflare_zero_trust_gateway_logging` | — | What Gateway writes to logs |
| `cloudflare_zero_trust_gateway_certificate` | — | Inspection certificate for TLS decryption |
| `cloudflare_zero_trust_gateway_proxy_endpoint` | `cloudflare_teams_proxy_endpoint` | Explicit proxy ingress |
| `cloudflare_zero_trust_list` | `cloudflare_teams_list` | Reusable domain, IP, email and serial lists |
| `cloudflare_zero_trust_dns_location` | `cloudflare_teams_location` | DNS resolver endpoints per site |

## Rule shape

`filters` picks the traffic type, `traffic`, `identity` and `device_posture` are Wirefilter expressions, and
`precedence` orders evaluation, lowest first.

```hcl
policies = {
  block_malware = {
    action     = "block"
    filters    = ["dns"]
    precedence = 100
    traffic    = "any(dns.security_category[*] in {80 83 117 131})"
    rule_settings = {
      block_page_enabled = true
      block_reason       = "Blocked by security policy"
    }
  }
}
```

Reference a list from an expression with `any(dns.domains[*] in $${cf.list.<id>})`, taking the ID from the
`list_ids` output.

## Singletons

`settings` and `logging` are one object per Cloudflare account, not collections. Leave either null and this
module does not create the resource, so two stacks do not silently overwrite each other. Only one stack in your
organisation should set them.

## Usage

```hcl
module "gateway" {
  source  = "terraform-cf-modules/zero-trust/cloudflare//modules/gateway-policy"
  version = "~> 0.1"

  enabled    = true
  account_id = var.account_id

  lists = {
    blocked_domains = {
      type  = "DOMAIN"
      items = [{ value = "malware.example" }]
    }
  }

  policies = {
    block_list = {
      action     = "block"
      filters    = ["dns"]
      precedence = 100
      traffic    = "any(dns.domains[*] == \"malware.example\")"
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
