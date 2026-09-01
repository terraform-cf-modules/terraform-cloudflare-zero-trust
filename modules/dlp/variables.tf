variable "enabled" {
  description = "Whether to create the resources managed by this submodule."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Cloudflare account ID. Every DLP resource is account scoped."
  type        = string
  default     = null

  validation {
    condition     = var.account_id == null || can(regex("^[0-9a-f]{32}$", var.account_id))
    error_message = "account_id must be a 32 character lowercase hexadecimal Cloudflare account ID."
  }
}

variable "profiles" {
  description = <<-EOT
    Custom DLP profiles, keyed by a stable identifier.

    `entries` are detections owned by the profile and defined inline. `shared_entries` reference detections that
    already exist, such as Cloudflare predefined entries or entries from a dataset.
  EOT
  type = map(object({
    name                 = optional(string)
    description          = optional(string)
    ai_context_enabled   = optional(bool)
    allowed_match_count  = optional(number)
    confidence_threshold = optional(string)
    ocr_enabled          = optional(bool)
    data_classes         = optional(list(string))
    data_tags            = optional(list(string))

    entries = optional(list(object({
      name        = string
      enabled     = bool
      description = optional(string)
      entry_id    = optional(string)
      pattern = object({
        regex      = string
        validation = optional(string)
      })
    })), [])

    shared_entries = optional(list(object({
      enabled    = bool
      entry_id   = string
      entry_type = string
    })), [])

    sensitivity_levels = optional(list(object({
      group_id = string
      level_id = string
    })))
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.profiles) :
      alltrue([for e in p.entries : e.pattern.validation == null || e.pattern.validation == "luhn"])
    ])
    error_message = "The only DLP pattern validation the provider accepts is luhn."
  }

  validation {
    condition = alltrue([
      for p in values(var.profiles) :
      alltrue([
        for e in p.shared_entries :
        contains(["custom", "predefined", "integration", "exact_data", "document_fingerprint"], e.entry_type)
      ])
    ])
    error_message = "Each shared entry entry_type must be one of custom, predefined, integration, exact_data, document_fingerprint."
  }

  validation {
    condition = alltrue([
      for p in values(var.profiles) :
      alltrue([for e in p.entries : can(regex("", e.pattern.regex)) && length(e.pattern.regex) > 0])
    ])
    error_message = "Every DLP entry pattern regex must be a non empty string."
  }
}

variable "entries" {
  description = "Standalone custom DLP entries, keyed by a stable identifier. Set `profile_key` to attach one to a profile created by this module, or `profile_id` to attach it to an existing profile."
  type = map(object({
    name        = optional(string)
    enabled     = bool
    description = optional(string)
    profile_key = optional(string)
    profile_id  = optional(string)
    pattern = object({
      regex      = string
      validation = optional(string)
    })
  }))
  default = {}

  validation {
    condition = alltrue([
      for e in values(var.entries) :
      e.profile_key == null || e.profile_id == null
    ])
    error_message = "A DLP entry cannot set both profile_key and profile_id."
  }

  validation {
    condition = alltrue([
      for e in values(var.entries) :
      e.profile_key == null || contains(keys(var.profiles), e.profile_key)
    ])
    error_message = "Every DLP entry profile_key must name a key in var.profiles."
  }

  validation {
    condition = alltrue([
      for e in values(var.entries) :
      e.pattern.validation == null || e.pattern.validation == "luhn"
    ])
    error_message = "The only DLP pattern validation the provider accepts is luhn."
  }
}

variable "datasets" {
  description = "DLP datasets for exact data match and document fingerprinting, keyed by a stable identifier. Upload the cell data out of band, Terraform only manages the container."
  type = map(object({
    name             = optional(string)
    description      = optional(string)
    case_sensitive   = optional(bool)
    encoding_version = optional(number)
    secret           = optional(bool)
    dataset_id       = optional(string)
  }))
  default = {}
}

variable "settings" {
  description = "Account wide DLP settings. One object per account, so leave it null to manage nothing."
  type = object({
    ai_context_analysis = optional(bool)
    ocr                 = optional(bool)
    payload_logging = optional(object({
      masking_level = optional(string)
      public_key    = optional(string)
    }))
  })
  default = null

  validation {
    condition = (
      var.settings == null ||
      try(var.settings.payload_logging.masking_level, null) == null ||
      contains(["full", "partial", "clear", "default"], var.settings.payload_logging.masking_level)
    )
    error_message = "payload_logging.masking_level must be one of full, partial, clear, default."
  }
}
