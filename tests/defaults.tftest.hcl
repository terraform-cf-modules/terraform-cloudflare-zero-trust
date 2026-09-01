# Plan only. Runs on every pull request, including forks, with no credentials.

mock_provider "cloudflare" {
}

variables {
  account_id = "00000000000000000000000000000000"
  zone_id    = "00000000000000000000000000000000"
}

run "creates_nothing_when_disabled" {
  command = plan

  variables {
    enabled = false

    identity_providers = {
      otp = { type = "onetimepin", config = {} }
    }
    access_groups = {
      staff = { include = [{ email_domain = { domain = "example.com" } }] }
    }
    access_policies = {
      allow = { decision = "allow", include = [{ everyone = {} }] }
    }
    access_applications = {
      app = { domain = "app.example.com" }
    }
    tunnels = {
      edge = { name = "edge" }
    }
    gateway_policies = {
      block = { action = "block", filters = ["dns"], traffic = "any(dns.domains[*] == \"example.com\")" }
    }
  }

  assert {
    condition     = output.enabled == false
    error_message = "Module reported enabled while var.enabled was false."
  }

  assert {
    condition     = length(output.access_application_ids) == 0
    error_message = "Applications were created while the module was disabled."
  }

  assert {
    condition     = length(output.access_policy_ids) == 0
    error_message = "Access policies were created while the module was disabled."
  }

  assert {
    condition     = length(output.tunnel_ids) == 0
    error_message = "Tunnels were created while the module was disabled."
  }

  assert {
    condition     = length(output.gateway_policy_ids) == 0
    error_message = "Gateway policies were created while the module was disabled."
  }
}

run "enabled_by_default" {
  command = plan

  assert {
    condition     = output.enabled == true
    error_message = "Module should be enabled by default."
  }
}

run "empty_by_default" {
  command = plan

  assert {
    condition     = length(output.access_application_ids) == 0
    error_message = "The module created an application with no inputs."
  }

  assert {
    condition     = output.gateway_settings == null
    error_message = "Gateway settings are a per account singleton and must not be created unless asked for."
  }

  assert {
    condition     = output.device_settings == null
    error_message = "Device settings are a per account singleton and must not be created unless asked for."
  }

  assert {
    condition     = output.dlp_settings == null
    error_message = "DLP settings are a per account singleton and must not be created unless asked for."
  }

  assert {
    condition     = output.mtls_hostname_settings == null
    error_message = "mTLS hostname settings must not be created unless asked for."
  }
}

run "builds_a_working_access_posture" {
  command = plan

  variables {
    identity_providers = {
      otp = { name = "One time PIN", type = "onetimepin", config = {} }
    }

    service_tokens = {
      ci = { name = "ci", duration = "8760h" }
    }

    access_groups = {
      staff = { name = "Staff", include = [{ email_domain = { domain = "example.com" } }] }
    }

    access_policies = {
      allow_staff = {
        decision           = "allow"
        session_duration   = "24h"
        include            = []
        include_group_keys = ["staff"]
        require            = [{ auth_method = { auth_method = "mfa" } }]
      }
      allow_ci = {
        decision                   = "non_identity"
        include                    = []
        include_service_token_keys = ["ci"]
      }
    }

    access_custom_pages = {
      denied = { type = "forbidden", custom_html = "<html></html>" }
    }

    access_applications = {
      intranet = {
        name             = "Intranet"
        type             = "self_hosted"
        domain           = "intranet.example.com"
        destinations     = [{ type = "public", uri = "intranet.example.com" }]
        policy_keys      = ["allow_staff", "allow_ci"]
        allowed_idp_keys = ["otp"]
        custom_page_keys = ["denied"]
      }
    }

    short_lived_certificates = {
      intranet = { app_key = "intranet" }
    }
  }

  assert {
    condition     = length(output.access_policy_ids) == 2
    error_message = "Expected two Access policies."
  }

  assert {
    condition     = length(output.access_group_ids) == 1
    error_message = "Expected one Access group."
  }

  assert {
    condition     = length(output.access_application_ids) == 1
    error_message = "Expected one Access application."
  }

  assert {
    condition     = length(output.identity_provider_ids) == 1
    error_message = "Expected one identity provider."
  }

  assert {
    condition     = length(output.short_lived_certificate_ids) == 1
    error_message = "Expected one short lived certificate, wired to the application by app_key."
  }
}

run "builds_gateway_tunnel_posture_and_dlp" {
  command = plan

  variables {
    gateway_lists = {
      blocked = { type = "DOMAIN", items = [{ value = "malware.example" }] }
    }

    gateway_policies = {
      block = {
        action     = "block"
        filters    = ["dns"]
        precedence = 100
        traffic    = "any(dns.domains[*] == \"malware.example\")"
        rule_settings = {
          block_page_enabled = true
          block_reason       = "Blocked"
        }
      }
    }

    tunnel_virtual_networks = {
      prod = { name = "prod", is_default_network = true }
    }

    tunnels = {
      edge = {
        name       = "edge"
        config_src = "cloudflare"
        config = {
          ingress = [
            { hostname = "app.example.com", service = "http://localhost:8080" },
            { service = "http_status:404" },
          ]
        }
      }
    }

    tunnel_routes = {
      vpc = { tunnel_key = "edge", virtual_network_key = "prod", network = "10.0.0.0/16" }
    }

    device_posture_rules = {
      min_macos = {
        type  = "os_version"
        match = [{ platform = "mac" }]
        input = { operating_system = "mac", version = "14.0.0", operator = ">=" }
      }
    }

    dlp_profiles = {
      pii = { name = "PII" }
    }

    dlp_entries = {
      employee_id = {
        enabled     = true
        profile_key = "pii"
        pattern     = { regex = "EMP-[0-9]{6}" }
      }
    }
  }

  assert {
    condition     = length(output.gateway_policy_ids) == 1
    error_message = "Expected one Gateway policy."
  }

  assert {
    condition     = length(output.gateway_list_ids) == 1
    error_message = "Expected one Zero Trust list."
  }

  assert {
    condition     = length(output.tunnel_ids) == 1
    error_message = "Expected one tunnel."
  }

  assert {
    condition     = length(output.tunnel_route_ids) == 1
    error_message = "Expected one tunnel route."
  }

  assert {
    condition     = length(output.device_posture_rule_ids) == 1
    error_message = "Expected one device posture rule."
  }

  assert {
    condition     = length(output.dlp_entry_ids) == 1
    error_message = "Expected one DLP entry."
  }
}
