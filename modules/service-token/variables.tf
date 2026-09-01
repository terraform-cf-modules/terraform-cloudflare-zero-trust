variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID that owns the service tokens."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "zone_id" {
  description = "Cloudflare zone ID, for zone scoped service tokens."
  type        = string
  default     = null

  validation {
    condition     = var.zone_id == null || can(regex("^[0-9a-f]{32}$", var.zone_id))
    error_message = "zone_id must be a 32 character lowercase hexadecimal Cloudflare zone ID."
  }
}

variable "service_tokens" {
  description = <<-EOT
    Access service tokens for machine to machine authentication, keyed by a stable identifier.

    `duration` is the token lifetime, for example `8760h`. Bump `client_secret_version` to rotate the secret;
    `previous_client_secret_expires_at` sets how long the old secret keeps working during the rotation.
  EOT
  type = map(object({
    name                              = optional(string)
    duration                          = optional(string)
    enabled                           = optional(bool)
    client_secret_version             = optional(number)
    previous_client_secret_expires_at = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for t in values(var.service_tokens) :
      t.duration == null || can(regex("^([0-9]+(ns|us|µs|ms|s|m|h))+$", t.duration))
    ])
    error_message = "service token duration must look like 8760h. Valid units are ns, us, µs, ms, s, m, h."
  }
}

variable "short_lived_certificates" {
  description = "Short lived certificate (SSH CA) issuers, keyed by a stable identifier. `app_id` is the ID of the Access application to issue certificates for."
  type = map(object({
    app_id = string
  }))
  default = {}
}
