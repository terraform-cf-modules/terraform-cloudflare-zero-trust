# Every optional feature of the Cloudflare Zero Trust module turned on.
#
# Identity, mTLS, service tokens, Access groups, policies, applications, custom
# pages, Gateway lists, rules, settings and logging, a Cloudflared tunnel with
# ingress rules and a private route, device posture and WARP profiles, and DLP.

provider "cloudflare" {
  # Reads CLOUDFLARE_API_TOKEN from the environment.
}

module "this" {
  source = "../../"

  enabled    = true
  account_id = var.account_id

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  identity_providers = {
    otp = {
      name   = "One time PIN"
      type   = "onetimepin"
      config = {}
    }

    okta = {
      name = "Okta"
      type = "okta"
      config = {
        client_id     = var.okta_client_id
        client_secret = var.okta_client_secret
        okta_account  = var.okta_account_url
      }
      scim_config = {
        enabled                  = true
        identity_update_behavior = "automatic"
        user_deprovision         = true
      }
    }
  }

  mtls_certificates = {
    corp_ca = {
      name                 = "Corporate CA"
      certificate          = var.mtls_certificate_pem
      associated_hostnames = [var.application_domain]
    }
  }

  mtls_hostname_settings = [
    {
      hostname                      = var.application_domain
      china_network                 = false
      client_certificate_forwarding = true
    },
  ]

  # ---------------------------------------------------------------------------
  # Service tokens
  # ---------------------------------------------------------------------------
  service_tokens = {
    ci = {
      name     = "ci-pipeline"
      duration = "8760h"
      enabled  = true
    }
  }

  short_lived_certificates = {
    bastion = {
      app_key = "bastion"
    }
  }

  # ---------------------------------------------------------------------------
  # Access groups, tags and policies
  # ---------------------------------------------------------------------------
  access_tags = {
    internal = { name = "internal" }
  }

  access_groups = {
    staff = {
      name    = "Staff"
      include = [{ email_domain = { domain = var.email_domain } }]
    }

    contractors = {
      name    = "Contractors"
      include = [{ email = { email = "contractor@partner.example" } }]
    }
  }

  access_policies = {
    allow_staff = {
      name                           = "Allow staff with MFA"
      decision                       = "allow"
      session_duration               = "24h"
      purpose_justification_required = true
      purpose_justification_prompt   = "Why do you need access?"
      isolation_required             = false
      include                        = []
      include_group_keys             = ["staff"]
      include_login_method_idp_keys  = ["okta"]
      exclude_group_keys             = ["contractors"]
      require                        = [{ auth_method = { auth_method = "mfa" } }]
      mfa_config = {
        allowed_authenticators = ["totp", "security_key"]
        session_duration       = "24h"
      }
      approval_required = true
      approval_groups = [
        {
          approvals_needed = 1
          email_addresses  = ["security@example.com"]
        },
      ]
    }

    allow_ci = {
      name                       = "Allow CI service token"
      decision                   = "non_identity"
      include                    = []
      include_service_token_keys = ["ci"]
    }
  }

  # ---------------------------------------------------------------------------
  # Applications and custom pages
  # ---------------------------------------------------------------------------
  access_custom_pages = {
    denied = {
      name        = "Access denied"
      type        = "forbidden"
      custom_html = "<html><body><h1>No access</h1></body></html>"
    }
  }

  access_applications = {
    intranet = {
      name                        = "Intranet"
      type                        = "self_hosted"
      domain                      = var.application_domain
      session_duration            = "24h"
      tags                        = ["internal"]
      auto_redirect_to_identity   = false
      app_launcher_visible        = true
      allow_authenticate_via_warp = true
      enable_binding_cookie       = true
      http_only_cookie_attribute  = true
      options_preflight_bypass    = false
      custom_deny_message         = "Ask #it-support for access."
      destinations                = [{ type = "public", uri = var.application_domain }]
      policy_keys                 = ["allow_staff", "allow_ci"]
      allowed_idp_keys            = ["otp", "okta"]
      custom_page_keys            = ["denied"]

      cors_headers = {
        allow_all_methods = true
        allowed_origins   = ["https://${var.application_domain}"]
        allow_credentials = true
        max_age           = 300
      }
    }

    bastion = {
      name             = "Bastion"
      type             = "ssh"
      domain           = "ssh.${var.email_domain}"
      session_duration = "1h"
      destinations     = [{ type = "public", uri = "ssh.${var.email_domain}" }]
      policy_keys      = ["allow_staff"]
    }

    launcher = {
      name        = "App Launcher"
      type        = "app_launcher"
      policy_keys = ["allow_staff"]

      footer_links = [
        { name = "Support", url = "https://support.example.com" },
      ]

      landing_page_design = {
        title             = "Example Apps"
        message           = "Pick an application."
        button_color      = "#0051c3"
        button_text_color = "#ffffff"
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Gateway
  # ---------------------------------------------------------------------------
  gateway_lists = {
    blocked_domains = {
      name        = "Blocked domains"
      type        = "DOMAIN"
      description = "Domains blocked by policy"
      items = [
        { value = "malware.example", description = "Known bad" },
      ]
    }
  }

  gateway_policies = {
    block_security_categories = {
      name        = "Block security risks"
      description = "DNS block for security categories"
      action      = "block"
      filters     = ["dns"]
      precedence  = 100
      traffic     = "any(dns.security_category[*] in {80 83 117 131})"
      rule_settings = {
        block_page_enabled = true
        block_reason       = "Blocked by security policy"
        notification_settings = {
          enabled     = true
          msg         = "This site is blocked."
          support_url = "https://support.example.com"
        }
      }
    }

    inspect_http = {
      name       = "Inspect HTTP"
      action     = "allow"
      filters    = ["http"]
      precedence = 200
      traffic    = "http.request.uri matches \".*\""
      rule_settings = {
        untrusted_cert = { action = "block" }
        check_session = {
          duration = "24h"
          enforce  = true
        }
      }
      schedule = {
        mon       = "08:00-18:00"
        tue       = "08:00-18:00"
        wed       = "08:00-18:00"
        thu       = "08:00-18:00"
        fri       = "08:00-18:00"
        time_zone = "Europe/London"
      }
    }
  }

  gateway_settings = {
    activity_log       = { enabled = true }
    protocol_detection = { enabled = true }
    tls_decrypt        = { enabled = true }
    browser_isolation = {
      url_browser_isolation_enabled = true
      non_identity_enabled          = false
    }
    block_page = {
      enabled     = true
      mode        = "customized_block_page"
      name        = "Example"
      header_text = "Blocked"
      footer_text = "Contact IT if this is wrong."
    }
  }

  gateway_logging = {
    redact_pii = true
    settings_by_rule_type = {
      dns  = { log_all = true, log_blocks = true }
      http = { log_all = false, log_blocks = true }
      l4   = { log_all = false, log_blocks = true }
    }
  }

  gateway_certificates = {
    inspection = {
      validity_period_days = 1826
      activate             = false
    }
  }

  gateway_proxy_endpoints = {
    office = {
      name = "Head office"
      ips  = ["203.0.113.1/32"]
    }
  }

  dns_locations = {
    hq = {
      name           = "Head office"
      client_default = true
      ecs_support    = false
      networks       = [{ network = "203.0.113.0/24" }]
      max_ttl        = { mode = "override", ttl_secs = 300 }
      endpoints = {
        doh  = { enabled = true, require_token = false }
        dot  = { enabled = true }
        ipv4 = { enabled = true }
        ipv6 = { enabled = false }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Tunnels
  # ---------------------------------------------------------------------------
  tunnel_virtual_networks = {
    prod = {
      name               = "production"
      comment            = "Production VPC"
      is_default_network = true
    }
  }

  tunnels = {
    edge = {
      name       = "edge"
      config_src = "cloudflare"
      config = {
        origin_request = {
          connect_timeout = 30
          no_tls_verify   = false
        }
        ingress = [
          {
            hostname = var.application_domain
            service  = "http://localhost:8080"
            origin_request = {
              http_host_header = var.application_domain
              connect_timeout  = 10
            }
          },
          {
            hostname = "ssh.${var.email_domain}"
            service  = "ssh://localhost:22"
          },
          {
            service = "http_status:404"
          },
        ]
      }
    }
  }

  tunnel_routes = {
    prod_vpc = {
      tunnel_key          = "edge"
      virtual_network_key = "prod"
      network             = "10.0.0.0/16"
      comment             = "Production VPC"
    }
  }

  # ---------------------------------------------------------------------------
  # Device posture and WARP profiles
  # ---------------------------------------------------------------------------
  device_posture_rules = {
    min_macos = {
      name  = "macOS 14 or newer"
      type  = "os_version"
      match = [{ platform = "mac" }]
      input = {
        operating_system = "mac"
        version          = "14.0.0"
        operator         = ">="
      }
    }

    disk_encrypted = {
      name  = "Disk encryption"
      type  = "disk_encryption"
      match = [{ platform = "mac" }, { platform = "windows" }]
      input = {
        require_all = true
      }
    }
  }

  device_managed_networks = {
    office = {
      name = "Head office"
      type = "tls"
      config = {
        tls_sockaddr = "192.0.2.1:443"
        sha256       = var.managed_network_sha256
      }
    }
  }

  device_settings = {
    gateway_proxy_enabled                 = true
    gateway_udp_proxy_enabled             = true
    root_certificate_installation_enabled = true
    use_zt_virtual_ip                     = false
  }

  device_default_profile = {
    allow_mode_switch     = true
    allow_updates         = true
    auto_connect          = 0
    captive_portal        = 180
    switch_locked         = false
    disable_auto_fallback = false
    support_url           = "https://support.example.com"
    exclude = [
      { address = "10.0.0.0/8", description = "RFC1918" },
    ]
  }

  device_custom_profiles = {
    engineering = {
      name        = "Engineering"
      description = "Engineering laptops"
      match       = "identity.email matches \".*@example[.]com\""
      precedence  = 100
      enabled     = true
      exclude = [
        { address = "192.168.0.0/16", description = "Home networks" },
      ]
    }
  }

  # ---------------------------------------------------------------------------
  # DLP
  # ---------------------------------------------------------------------------
  dlp_profiles = {
    pii = {
      name                = "Internal PII"
      description         = "Employee identifiers"
      ocr_enabled         = true
      allowed_match_count = 0
    }
  }

  # Detections are declared as standalone entries. The inline `entries` list on a
  # profile still works but the provider marks it for sunset on 01/01/2026.
  dlp_entries = {
    employee_id = {
      name        = "Employee ID"
      enabled     = true
      profile_key = "pii"
      pattern     = { regex = "EMP-[0-9]{6}" }
    }

    project_code = {
      name        = "Project code"
      enabled     = true
      profile_key = "pii"
      pattern     = { regex = "PRJ-[A-Z]{4}" }
    }
  }

  dlp_datasets = {
    customer_ids = {
      name        = "Customer identifiers"
      description = "Exact data match source"
      secret      = true
    }
  }

  dlp_settings = {
    ocr                 = true
    ai_context_analysis = false
    payload_logging = {
      masking_level = "partial"
    }
  }
}
