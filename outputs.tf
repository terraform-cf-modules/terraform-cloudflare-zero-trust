output "enabled" {
  description = "Whether this module created its resources."
  value       = local.enabled
}

# -----------------------------------------------------------------------------
# Identity
# -----------------------------------------------------------------------------

output "identity_provider_ids" {
  description = "Map of identity provider key to provider ID."
  value       = module.identity.identity_provider_ids
}

output "identity_providers" {
  description = "Full identity provider objects. Sensitive, config carries the OAuth client secret."
  value       = module.identity.identity_providers
  sensitive   = true
}

output "mtls_certificate_ids" {
  description = "Map of mTLS certificate key to certificate ID."
  value       = module.identity.mtls_certificate_ids
}

output "mtls_hostname_settings" {
  description = "The mTLS hostname settings object, or null when none are managed."
  value       = module.identity.mtls_hostname_settings
}

# -----------------------------------------------------------------------------
# Service tokens and short lived certificates
# -----------------------------------------------------------------------------

output "service_token_ids" {
  description = "Map of service token key to token ID."
  value       = module.service_token.service_token_ids
}

output "service_token_client_ids" {
  description = "Map of service token key to client ID, sent as the CF-Access-Client-Id header."
  value       = module.service_token.service_token_client_ids
}

output "service_token_client_secrets" {
  description = "Map of service token key to client secret, sent as the CF-Access-Client-Secret header. Sensitive."
  value       = module.service_token.service_token_client_secrets
  sensitive   = true
}

output "short_lived_certificate_ids" {
  description = "Map of short lived certificate key to certificate ID."
  value       = module.short_lived_certificate.short_lived_certificate_ids
}

output "short_lived_certificate_public_keys" {
  description = "Map of short lived certificate key to the SSH CA public key to install on target hosts."
  value       = module.short_lived_certificate.short_lived_certificate_public_keys
}

# -----------------------------------------------------------------------------
# Access groups, policies and tags
# -----------------------------------------------------------------------------

output "access_tag_ids" {
  description = "Map of Access tag key to tag ID."
  value       = module.access_policy.access_tag_ids
}

output "access_group_ids" {
  description = "Map of Access group key to group ID."
  value       = module.access_policy.access_group_ids
}

output "access_groups" {
  description = "Full Access group objects."
  value       = module.access_policy.access_groups
}

output "access_policy_ids" {
  description = "Map of Access policy key to policy ID."
  value       = module.access_policy.access_policy_ids
}

output "access_policies" {
  description = "Full Access policy objects."
  value       = module.access_policy.access_policies
}

# -----------------------------------------------------------------------------
# Access applications
# -----------------------------------------------------------------------------

output "access_application_ids" {
  description = "Map of application key to application ID."
  value       = module.access_app.application_ids
}

output "access_application_auds" {
  description = "Map of application key to the application audience (AUD) tag used to validate Access JWTs."
  value       = module.access_app.application_auds
}

output "access_application_domains" {
  description = "Map of application key to the primary domain it protects."
  value       = module.access_app.application_domains
}

output "access_applications" {
  description = "Full Access application objects. Sensitive, scim_config can carry credentials."
  value       = module.access_app.applications
  sensitive   = true
}

output "access_custom_page_ids" {
  description = "Map of Access custom page key to page ID."
  value       = module.access_app.custom_page_ids
}

# -----------------------------------------------------------------------------
# Gateway
# -----------------------------------------------------------------------------

output "gateway_list_ids" {
  description = "Map of Zero Trust list key to list ID."
  value       = module.gateway_policy.list_ids
}

output "gateway_policy_ids" {
  description = "Map of Gateway policy key to policy ID."
  value       = module.gateway_policy.policy_ids
}

output "gateway_policies" {
  description = "Full Gateway policy objects."
  value       = module.gateway_policy.policies
}

output "gateway_settings" {
  description = "The account wide Gateway settings object, or null when not managed here."
  value       = module.gateway_policy.settings
}

output "gateway_logging" {
  description = "The account wide Gateway logging object, or null when not managed here."
  value       = module.gateway_policy.logging
}

output "gateway_certificate_ids" {
  description = "Map of Gateway certificate key to certificate ID."
  value       = module.gateway_policy.certificate_ids
}

output "gateway_proxy_endpoint_ids" {
  description = "Map of proxy endpoint key to endpoint ID."
  value       = module.gateway_policy.proxy_endpoint_ids
}

output "gateway_proxy_endpoint_subdomains" {
  description = "Map of proxy endpoint key to the Cloudflare subdomain clients connect through."
  value       = module.gateway_policy.proxy_endpoint_subdomains
}

output "dns_location_ids" {
  description = "Map of DNS location key to location ID."
  value       = module.gateway_policy.dns_location_ids
}

output "dns_location_doh_subdomains" {
  description = "Map of DNS location key to its DNS over HTTPS subdomain."
  value       = module.gateway_policy.dns_location_doh_subdomains
}

# -----------------------------------------------------------------------------
# Tunnels
# -----------------------------------------------------------------------------

output "tunnel_ids" {
  description = "Map of tunnel key to tunnel ID."
  value       = module.tunnel.tunnel_ids
}

output "tunnel_cnames" {
  description = "Map of tunnel key to the CNAME target a proxied DNS record should point at."
  value       = module.tunnel.tunnel_cnames
}

output "tunnel_secrets" {
  description = "Map of tunnel key to tunnel secret. Sensitive."
  value       = module.tunnel.tunnel_secrets
  sensitive   = true
}

output "tunnel_tokens" {
  description = "Map of tunnel key to the base64 connector token for `cloudflared tunnel run --token`. Sensitive."
  value       = module.tunnel.tunnel_tokens
  sensitive   = true
}

output "tunnel_virtual_network_ids" {
  description = "Map of virtual network key to virtual network ID."
  value       = module.tunnel.virtual_network_ids
}

output "tunnel_route_ids" {
  description = "Map of route key to route ID."
  value       = module.tunnel.route_ids
}

# -----------------------------------------------------------------------------
# Device posture
# -----------------------------------------------------------------------------

output "device_posture_rule_ids" {
  description = "Map of posture rule key to rule ID."
  value       = module.device_posture.posture_rule_ids
}

output "device_posture_integration_ids" {
  description = "Map of posture integration key to integration ID."
  value       = module.device_posture.posture_integration_ids
}

output "device_managed_network_ids" {
  description = "Map of managed network key to network ID."
  value       = module.device_posture.managed_network_ids
}

output "device_settings" {
  description = "The account wide device settings object, or null when not managed here."
  value       = module.device_posture.device_settings
}

output "device_default_profile" {
  description = "The default WARP profile object, or null when not managed here."
  value       = module.device_posture.default_profile
}

output "device_custom_profile_ids" {
  description = "Map of custom WARP profile key to profile ID."
  value       = module.device_posture.custom_profile_ids
}

# -----------------------------------------------------------------------------
# DLP
# -----------------------------------------------------------------------------

output "dlp_profile_ids" {
  description = "Map of DLP profile key to profile ID."
  value       = module.dlp.profile_ids
}

output "dlp_entry_ids" {
  description = "Map of DLP entry key to entry ID."
  value       = module.dlp.entry_ids
}

output "dlp_dataset_ids" {
  description = "Map of DLP dataset key to dataset ID."
  value       = module.dlp.dataset_ids
}

output "dlp_settings" {
  description = "The account wide DLP settings object, or null when not managed here."
  value       = module.dlp.settings
}
