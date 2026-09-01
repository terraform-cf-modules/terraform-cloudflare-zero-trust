variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the tunnels. Required, every tunnel resource is account scoped."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "tunnels" {
  description = <<-EOT
    Cloudflared tunnels, keyed by a stable identifier.

    `config_src` decides who owns the ingress rules. Use `cloudflare` to manage them here through `config`,
    or `local` when the cloudflared process reads its own config file, in which case leave `config` null.

    `tunnel_secret` is a base64 encoded 32 byte secret. Leave it null and Cloudflare generates one.
  EOT
  type = map(object({
    name          = optional(string)
    config_src    = optional(string, "cloudflare")
    tunnel_secret = optional(string)

    config = optional(object({
      ingress = optional(list(object({
        service  = string
        hostname = optional(string)
        path     = optional(string)
        origin_request = optional(object({
          access = optional(object({
            aud_tag   = list(string)
            team_name = string
            required  = optional(bool)
          }))
          ca_pool                  = optional(string)
          connect_timeout          = optional(number)
          disable_chunked_encoding = optional(bool)
          http2_origin             = optional(bool)
          http_host_header         = optional(string)
          keep_alive_connections   = optional(number)
          keep_alive_timeout       = optional(number)
          match_sn_ito_host        = optional(bool)
          no_happy_eyeballs        = optional(bool)
          no_tls_verify            = optional(bool)
          origin_server_name       = optional(string)
          proxy_type               = optional(string)
          tcp_keep_alive           = optional(number)
          tls_timeout              = optional(number)
        }))
      })), [])

      origin_request = optional(object({
        access = optional(object({
          aud_tag   = list(string)
          team_name = string
          required  = optional(bool)
        }))
        ca_pool                  = optional(string)
        connect_timeout          = optional(number)
        disable_chunked_encoding = optional(bool)
        http2_origin             = optional(bool)
        http_host_header         = optional(string)
        keep_alive_connections   = optional(number)
        keep_alive_timeout       = optional(number)
        match_sn_ito_host        = optional(bool)
        no_happy_eyeballs        = optional(bool)
        no_tls_verify            = optional(bool)
        origin_server_name       = optional(string)
        proxy_type               = optional(string)
        tcp_keep_alive           = optional(number)
        tls_timeout              = optional(number)
      }))
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      contains(["local", "cloudflare"], t.config_src)
    ])
    error_message = "Each tunnel config_src must be local or cloudflare."
  }

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      t.config == null || t.config_src == "cloudflare"
    ])
    error_message = "A tunnel can only carry a config block when config_src is cloudflare. With config_src = local the cloudflared process owns its own configuration."
  }

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      t.config == null || length(coalesce(t.config.ingress, [])) == 0 ||
      alltrue([
        for r in slice(t.config.ingress, 0, max(length(t.config.ingress) - 1, 0)) :
        r.hostname != null || r.path != null
      ])
    ])
    error_message = "Only the last ingress rule may be a catch all. Every earlier rule needs a hostname or a path."
  }

  validation {
    condition = alltrue([
      for t in values(var.tunnels) :
      t.config == null || length(coalesce(t.config.ingress, [])) == 0 ||
      element(t.config.ingress, length(t.config.ingress) - 1).hostname == null
    ])
    error_message = "The final ingress rule must be a catch all with no hostname, for example { service = \"http_status:404\" }."
  }
}

variable "virtual_networks" {
  description = "Tunnel virtual networks, keyed by a stable identifier. Virtual networks let overlapping private CIDRs coexist in one account."
  type = map(object({
    name               = optional(string)
    comment            = optional(string)
    is_default_network = optional(bool)
  }))
  default = {}
}

variable "routes" {
  description = <<-EOT
    Private network routes advertised through a tunnel, keyed by a stable identifier.

    Set `tunnel_key` to point at a tunnel created by this same module, or `tunnel_id` to point at an existing one.
    Likewise `virtual_network_key` for a virtual network created here, or `virtual_network_id` for an existing one.
  EOT
  type = map(object({
    network             = string
    comment             = optional(string)
    tunnel_key          = optional(string)
    tunnel_id           = optional(string)
    virtual_network_key = optional(string)
    virtual_network_id  = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      (r.tunnel_key == null) != (r.tunnel_id == null)
    ])
    error_message = "Each route must set exactly one of tunnel_key or tunnel_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      r.virtual_network_key == null || r.virtual_network_id == null
    ])
    error_message = "A route cannot set both virtual_network_key and virtual_network_id."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      can(cidrnetmask(r.network)) || can(regex(":", r.network))
    ])
    error_message = "Each route network must be a CIDR block, for example 10.0.0.0/16."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      r.tunnel_key == null || contains(keys(var.tunnels), r.tunnel_key)
    ])
    error_message = "Every route tunnel_key must name a key in var.tunnels."
  }

  validation {
    condition = alltrue([
      for r in values(var.routes) :
      r.virtual_network_key == null || contains(keys(var.virtual_networks), r.virtual_network_key)
    ])
    error_message = "Every route virtual_network_key must name a key in var.virtual_networks."
  }
}
