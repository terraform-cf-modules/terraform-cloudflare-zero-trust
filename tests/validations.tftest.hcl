# Input validation. Plan only, no credentials.
# One run block per validation block in variables.tf.

mock_provider "cloudflare" {
}

variables {
  account_id = "00000000000000000000000000000000"
}

# -----------------------------------------------------------------------------
# Scope anchors
# -----------------------------------------------------------------------------

run "rejects_malformed_account_id" {
  command = plan

  variables {
    account_id = "not-a-valid-account-id"
  }

  expect_failures = [var.account_id]
}

run "rejects_malformed_zone_id" {
  command = plan

  variables {
    zone_id = "TOO-SHORT"
  }

  expect_failures = [var.zone_id]
}

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------

run "rejects_unknown_identity_provider_type" {
  command = plan

  variables {
    identity_providers = {
      bad = { type = "myspace", config = {} }
    }
  }

  expect_failures = [var.identity_providers]
}

run "rejects_unknown_identity_provider_prompt" {
  command = plan

  variables {
    identity_providers = {
      bad = { type = "oidc", config = { prompt = "shout" } }
    }
  }

  expect_failures = [var.identity_providers]
}

run "rejects_unknown_scim_identity_update_behavior" {
  command = plan

  variables {
    identity_providers = {
      bad = {
        type        = "okta"
        config      = {}
        scim_config = { identity_update_behavior = "guess" }
      }
    }
  }

  expect_failures = [var.identity_providers]
}

run "rejects_non_pem_mtls_certificate" {
  command = plan

  variables {
    mtls_certificates = {
      bad = { certificate = "this is not a certificate" }
    }
  }

  expect_failures = [var.mtls_certificates]
}

# -----------------------------------------------------------------------------
# Service tokens
# -----------------------------------------------------------------------------

run "rejects_malformed_service_token_duration" {
  command = plan

  variables {
    service_tokens = {
      bad = { duration = "one year" }
    }
  }

  expect_failures = [var.service_tokens]
}

run "rejects_short_lived_certificate_without_app" {
  command = plan

  variables {
    short_lived_certificates = {
      bad = {}
    }
  }

  expect_failures = [var.short_lived_certificates]
}

run "rejects_short_lived_certificate_app_key_that_does_not_exist" {
  command = plan

  variables {
    short_lived_certificates = {
      bad = { app_key = "nope" }
    }
  }

  expect_failures = [var.short_lived_certificates]
}

# -----------------------------------------------------------------------------
# Access groups and policies
# -----------------------------------------------------------------------------

run "rejects_access_group_with_no_include" {
  command = plan

  variables {
    access_groups = {
      bad = { include = [] }
    }
  }

  expect_failures = [var.access_groups]
}

run "rejects_unknown_policy_decision" {
  command = plan

  variables {
    access_policies = {
      bad = { decision = "maybe", include = [{ everyone = {} }] }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_policy_with_no_include" {
  command = plan

  variables {
    access_policies = {
      bad = { decision = "allow", include = [] }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_unknown_mfa_authenticator" {
  command = plan

  variables {
    access_policies = {
      bad = {
        decision   = "allow"
        include    = [{ everyone = {} }]
        mfa_config = { allowed_authenticators = ["carrier_pigeon"] }
      }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_approval_group_needing_zero_approvals" {
  command = plan

  variables {
    access_policies = {
      bad = {
        decision        = "allow"
        include         = [{ everyone = {} }]
        approval_groups = [{ approvals_needed = 0 }]
      }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_policy_group_key_that_does_not_exist" {
  command = plan

  variables {
    access_policies = {
      bad = {
        decision           = "allow"
        include            = []
        include_group_keys = ["nope"]
      }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_policy_service_token_key_that_does_not_exist" {
  command = plan

  variables {
    access_policies = {
      bad = {
        decision                   = "non_identity"
        include                    = []
        include_service_token_keys = ["nope"]
      }
    }
  }

  expect_failures = [var.access_policies]
}

run "rejects_policy_login_method_idp_key_that_does_not_exist" {
  command = plan

  variables {
    access_policies = {
      bad = {
        decision                      = "allow"
        include                       = []
        include_login_method_idp_keys = ["nope"]
      }
    }
  }

  expect_failures = [var.access_policies]
}

# -----------------------------------------------------------------------------
# Access applications and custom pages
# -----------------------------------------------------------------------------

run "rejects_unknown_application_type" {
  command = plan

  variables {
    access_applications = {
      bad = { type = "sharepoint" }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_saas_app_on_self_hosted_application" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type     = "self_hosted"
        saas_app = { auth_type = "saml" }
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_footer_links_outside_app_launcher" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type         = "self_hosted"
        footer_links = [{ name = "Docs", url = "https://example.com" }]
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_cors_headers_without_origins" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type         = "self_hosted"
        cors_headers = { allow_all_methods = true }
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_malformed_application_session_duration" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type             = "self_hosted"
        session_duration = "one day"
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_unknown_destination_type" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type         = "self_hosted"
        destinations = [{ type = "semi_public", uri = "app.example.com" }]
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_unknown_target_criteria_protocol" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type            = "infrastructure"
        target_criteria = [{ port = 22, protocol = "TELNET", target_attributes = { hostname = ["a"] } }]
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_unknown_saas_auth_type" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type     = "saas"
        saas_app = { auth_type = "kerberos" }
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_custom_page_key_that_does_not_exist" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type             = "self_hosted"
        custom_page_keys = ["nope"]
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_policy_key_that_does_not_exist" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type        = "self_hosted"
        policy_keys = ["nope"]
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_allowed_idp_key_that_does_not_exist" {
  command = plan

  variables {
    access_applications = {
      bad = {
        type             = "self_hosted"
        allowed_idp_keys = ["nope"]
      }
    }
  }

  expect_failures = [var.access_applications]
}

run "rejects_unknown_custom_page_type" {
  command = plan

  variables {
    access_custom_pages = {
      bad = { type = "teapot", custom_html = "<html></html>" }
    }
  }

  expect_failures = [var.access_custom_pages]
}

# -----------------------------------------------------------------------------
# Gateway
# -----------------------------------------------------------------------------

run "rejects_unknown_list_type" {
  command = plan

  variables {
    gateway_lists = {
      bad = { type = "PHONE" }
    }
  }

  expect_failures = [var.gateway_lists]
}

run "rejects_unknown_gateway_action" {
  command = plan

  variables {
    gateway_policies = {
      bad = { action = "ponder" }
    }
  }

  expect_failures = [var.gateway_policies]
}

run "rejects_unknown_gateway_filter" {
  command = plan

  variables {
    gateway_policies = {
      bad = { action = "block", filters = ["smtp"] }
    }
  }

  expect_failures = [var.gateway_policies]
}

run "rejects_unknown_untrusted_cert_action" {
  command = plan

  variables {
    gateway_policies = {
      bad = {
        action        = "allow"
        filters       = ["http"]
        rule_settings = { untrusted_cert = { action = "shrug" } }
      }
    }
  }

  expect_failures = [var.gateway_policies]
}

run "rejects_unknown_resolve_dns_internally_fallback" {
  command = plan

  variables {
    gateway_policies = {
      bad = {
        action        = "resolve"
        filters       = ["dns"]
        rule_settings = { resolve_dns_internally = { fallback = "somewhere" } }
      }
    }
  }

  expect_failures = [var.gateway_policies]
}

run "rejects_unknown_biso_version" {
  command = plan

  variables {
    gateway_policies = {
      bad = {
        action        = "isolate"
        filters       = ["http"]
        rule_settings = { biso_admin_controls = { version = "v9" } }
      }
    }
  }

  expect_failures = [var.gateway_policies]
}

run "rejects_out_of_range_certificate_validity" {
  command = plan

  variables {
    gateway_certificates = {
      bad = { validity_period_days = 99999 }
    }
  }

  expect_failures = [var.gateway_certificates]
}

run "rejects_unknown_proxy_endpoint_kind" {
  command = plan

  variables {
    gateway_proxy_endpoints = {
      bad = { kind = "carrier" }
    }
  }

  expect_failures = [var.gateway_proxy_endpoints]
}

run "rejects_unknown_dns_location_max_ttl_mode" {
  command = plan

  variables {
    dns_locations = {
      bad = { max_ttl = { mode = "whenever" } }
    }
  }

  expect_failures = [var.dns_locations]
}

# -----------------------------------------------------------------------------
# Tunnels
# -----------------------------------------------------------------------------

run "rejects_unknown_tunnel_config_src" {
  command = plan

  variables {
    tunnels = {
      bad = { config_src = "somewhere_else" }
    }
  }

  expect_failures = [var.tunnels]
}

run "rejects_remote_config_on_locally_managed_tunnel" {
  command = plan

  variables {
    tunnels = {
      bad = {
        config_src = "local"
        config = {
          ingress = [{ service = "http_status:404" }]
        }
      }
    }
  }

  expect_failures = [var.tunnels]
}

run "rejects_catch_all_ingress_rule_that_is_not_last" {
  command = plan

  variables {
    tunnels = {
      bad = {
        config_src = "cloudflare"
        config = {
          ingress = [
            { service = "http://localhost:8080" },
            { hostname = "app.example.com", service = "http://localhost:9090" },
          ]
        }
      }
    }
  }

  expect_failures = [var.tunnels]
}

run "rejects_ingress_without_a_catch_all" {
  command = plan

  variables {
    tunnels = {
      bad = {
        config_src = "cloudflare"
        config = {
          ingress = [
            { hostname = "app.example.com", service = "http://localhost:8080" },
          ]
        }
      }
    }
  }

  expect_failures = [var.tunnels]
}

run "rejects_route_without_a_tunnel" {
  command = plan

  variables {
    tunnel_routes = {
      bad = { network = "10.0.0.0/16" }
    }
  }

  expect_failures = [var.tunnel_routes]
}

run "rejects_route_with_two_virtual_networks" {
  command = plan

  variables {
    tunnel_routes = {
      bad = {
        network             = "10.0.0.0/16"
        tunnel_id           = "00000000000000000000000000000000"
        virtual_network_key = "a"
        virtual_network_id  = "00000000000000000000000000000000"
      }
    }
  }

  expect_failures = [var.tunnel_routes]
}

run "rejects_route_network_that_is_not_a_cidr" {
  command = plan

  variables {
    tunnel_routes = {
      bad = {
        network   = "not-a-cidr"
        tunnel_id = "00000000000000000000000000000000"
      }
    }
  }

  expect_failures = [var.tunnel_routes]
}

run "rejects_route_tunnel_key_that_does_not_exist" {
  command = plan

  variables {
    tunnel_routes = {
      bad = { network = "10.0.0.0/16", tunnel_key = "nope" }
    }
  }

  expect_failures = [var.tunnel_routes]
}

run "rejects_route_virtual_network_key_that_does_not_exist" {
  command = plan

  variables {
    tunnels = {
      edge = { name = "edge" }
    }
    tunnel_routes = {
      bad = { network = "10.0.0.0/16", tunnel_key = "edge", virtual_network_key = "nope" }
    }
  }

  expect_failures = [var.tunnel_routes]
}

# -----------------------------------------------------------------------------
# Device posture and profiles
# -----------------------------------------------------------------------------

run "rejects_unknown_posture_rule_type" {
  command = plan

  variables {
    device_posture_rules = {
      bad = { type = "vibes" }
    }
  }

  expect_failures = [var.device_posture_rules]
}

run "rejects_unknown_posture_match_platform" {
  command = plan

  variables {
    device_posture_rules = {
      bad = { type = "os_version", match = [{ platform = "beos" }] }
    }
  }

  expect_failures = [var.device_posture_rules]
}

run "rejects_unknown_posture_input_operator" {
  command = plan

  variables {
    device_posture_rules = {
      bad = { type = "os_version", input = { operator = "~=" } }
    }
  }

  expect_failures = [var.device_posture_rules]
}

run "rejects_unknown_posture_input_risk_level" {
  command = plan

  variables {
    device_posture_rules = {
      bad = { type = "warp", input = { risk_level = "spicy" } }
    }
  }

  expect_failures = [var.device_posture_rules]
}

run "rejects_unknown_posture_integration_type" {
  command = plan

  variables {
    device_posture_integrations = {
      bad = { type = "sccm", interval = "24h", config = {} }
    }
  }

  expect_failures = [var.device_posture_integrations]
}

run "rejects_unknown_managed_network_type" {
  command = plan

  variables {
    device_managed_networks = {
      bad = { type = "dns", config = { tls_sockaddr = "192.0.2.1:443" } }
    }
  }

  expect_failures = [var.device_managed_networks]
}

run "rejects_default_profile_with_include_and_exclude" {
  command = plan

  variables {
    device_default_profile = {
      include = [{ address = "10.0.0.0/8" }]
      exclude = [{ address = "192.168.0.0/16" }]
    }
  }

  expect_failures = [var.device_default_profile]
}

run "rejects_custom_profile_with_include_and_exclude" {
  command = plan

  variables {
    device_custom_profiles = {
      bad = {
        match   = "identity.email"
        include = [{ address = "10.0.0.0/8" }]
        exclude = [{ address = "192.168.0.0/16" }]
      }
    }
  }

  expect_failures = [var.device_custom_profiles]
}

# -----------------------------------------------------------------------------
# DLP
# -----------------------------------------------------------------------------

run "rejects_unknown_inline_entry_pattern_validation" {
  command = plan

  variables {
    dlp_profiles = {
      bad = {
        entries = [
          { name = "x", enabled = true, pattern = { regex = "abc", validation = "mod10" } },
        ]
      }
    }
  }

  expect_failures = [var.dlp_profiles]
}

run "rejects_unknown_shared_entry_type" {
  command = plan

  variables {
    dlp_profiles = {
      bad = {
        shared_entries = [
          { enabled = true, entry_id = "00000000000000000000000000000000", entry_type = "borrowed" },
        ]
      }
    }
  }

  expect_failures = [var.dlp_profiles]
}

run "rejects_empty_inline_entry_regex" {
  command = plan

  variables {
    dlp_profiles = {
      bad = {
        entries = [
          { name = "x", enabled = true, pattern = { regex = "" } },
        ]
      }
    }
  }

  expect_failures = [var.dlp_profiles]
}

run "rejects_dlp_entry_with_two_profiles" {
  command = plan

  variables {
    dlp_profiles = {
      pii = {}
    }
    dlp_entries = {
      bad = {
        enabled     = true
        profile_key = "pii"
        profile_id  = "00000000000000000000000000000000"
        pattern     = { regex = "abc" }
      }
    }
  }

  expect_failures = [var.dlp_entries]
}

run "rejects_dlp_entry_profile_key_that_does_not_exist" {
  command = plan

  variables {
    dlp_entries = {
      bad = {
        enabled     = true
        profile_key = "nope"
        pattern     = { regex = "abc" }
      }
    }
  }

  expect_failures = [var.dlp_entries]
}

run "rejects_unknown_dlp_entry_pattern_validation" {
  command = plan

  variables {
    dlp_entries = {
      bad = {
        enabled    = true
        profile_id = "00000000000000000000000000000000"
        pattern    = { regex = "abc", validation = "mod10" }
      }
    }
  }

  expect_failures = [var.dlp_entries]
}

run "rejects_unknown_payload_logging_masking_level" {
  command = plan

  variables {
    dlp_settings = {
      payload_logging = { masking_level = "blurry" }
    }
  }

  expect_failures = [var.dlp_settings]
}
