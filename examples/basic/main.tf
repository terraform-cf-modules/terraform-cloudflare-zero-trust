# Minimum viable configuration for the Cloudflare Zero Trust module.
#
# One identity provider, one Access group, one policy, one protected application.
# That is the smallest thing that is actually a Zero Trust posture rather than a
# pile of disconnected objects.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id

  identity_providers = {
    otp = {
      name   = "One time PIN"
      type   = "onetimepin"
      config = {}
    }
  }

  access_groups = {
    staff = {
      name    = "Staff"
      include = [{ email_domain = { domain = var.email_domain } }]
    }
  }

  access_policies = {
    allow_staff = {
      name               = "Allow staff"
      decision           = "allow"
      session_duration   = "24h"
      include            = []
      include_group_keys = ["staff"]
    }
  }

  access_applications = {
    intranet = {
      name             = "Intranet"
      type             = "self_hosted"
      domain           = var.application_domain
      session_duration = "24h"
      destinations     = [{ type = "public", uri = var.application_domain }]
      policy_keys      = ["allow_staff"]
      allowed_idp_keys = ["otp"]
    }
  }
}
