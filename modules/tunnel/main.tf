# -----------------------------------------------------------------------------
# Submodule: tunnel
#
#   cloudflare_zero_trust_tunnel_cloudflared                  (v4: cloudflare_tunnel)
#   cloudflare_zero_trust_tunnel_cloudflared_config           (v4: cloudflare_tunnel_config)
#   cloudflare_zero_trust_tunnel_cloudflared_route            (v4: cloudflare_tunnel_route)
#   cloudflare_zero_trust_tunnel_cloudflared_virtual_network  (v4: cloudflare_tunnel_virtual_network)
#
# The config resource is separate from the tunnel and only applies when the
# tunnel was created with config_src = "cloudflare". Its `config` attribute is a
# single object holding an ordered ingress list, and cloudflared requires the
# last ingress rule to be a catch all with no hostname.
#
# The virtual network resource still accepts `is_default` but the provider marks
# it deprecated, so this module exposes `is_default_network` instead.
# -----------------------------------------------------------------------------

locals {
  enabled = var.enabled

  tunnels          = local.enabled ? var.tunnels : {}
  virtual_networks = local.enabled ? var.virtual_networks : {}
  routes           = local.enabled ? var.routes : {}

  # Only tunnels that both own their configuration remotely and were given one.
  tunnel_configs = {
    for k, t in local.tunnels : k => t.config
    if t.config != null && t.config_src == "cloudflare"
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  for_each = local.tunnels

  account_id    = var.account_id
  name          = coalesce(each.value.name, each.key)
  config_src    = each.value.config_src
  tunnel_secret = each.value.tunnel_secret
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  for_each = local.tunnel_configs

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[each.key].id
  config     = each.value
}

resource "cloudflare_zero_trust_tunnel_cloudflared_virtual_network" "this" {
  for_each = local.virtual_networks

  account_id         = var.account_id
  name               = coalesce(each.value.name, each.key)
  comment            = each.value.comment
  is_default_network = each.value.is_default_network
}

resource "cloudflare_zero_trust_tunnel_cloudflared_route" "this" {
  for_each = local.routes

  account_id = var.account_id
  network    = each.value.network
  comment    = each.value.comment

  tunnel_id = (
    each.value.tunnel_key != null
    ? cloudflare_zero_trust_tunnel_cloudflared.this[each.value.tunnel_key].id
    : each.value.tunnel_id
  )

  virtual_network_id = (
    each.value.virtual_network_key != null
    ? cloudflare_zero_trust_tunnel_cloudflared_virtual_network.this[each.value.virtual_network_key].id
    : each.value.virtual_network_id
  )
}
