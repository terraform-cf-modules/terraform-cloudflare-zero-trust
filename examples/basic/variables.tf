variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "email_domain" {
  description = "Email domain allowed through the Access policy."
  type        = string
  default     = "example.com"
}

variable "application_domain" {
  description = "Hostname the Access application protects."
  type        = string
  default     = "intranet.example.com"
}
