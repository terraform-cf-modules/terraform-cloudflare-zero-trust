# Wrapper

Creates many instances of the root module from a single map, so a list of similar Zero Trust stacks does not need
a repeated `module` block per item. Useful when one Terraform state covers several Cloudflare accounts, or when a
team splits Zero Trust configuration by business unit.

```hcl
module "instances" {
  source = "terraform-cf-modules/zero-trust/cloudflare//wrappers"

  defaults = {
    account_id = var.account_id

    gateway_lists = {
      blocked = { type = "DOMAIN", items = [{ value = "malware.example" }] }
    }
  }

  items = {
    corp = {
      access_applications = {
        intranet = { domain = "intranet.example.com", destinations = [{ type = "public", uri = "intranet.example.com" }] }
      }
    }

    lab = {
      enabled = false
    }
  }
}
```

Keys in `items` become the state addresses, so keep them stable. Renaming a key destroys and recreates that
instance.

The `wrapper` output is marked `sensitive = true` because the root module exposes tunnel secrets and service
token client secrets. Read individual values with `module.instances.wrapper["corp"].access_application_ids`
rather than printing the whole object.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
