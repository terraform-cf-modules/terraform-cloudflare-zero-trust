variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "email_domain" {
  description = "Email domain allowed through the Access policies."
  type        = string
  default     = "example.com"
}

variable "application_domain" {
  description = "Hostname the primary Access application protects."
  type        = string
  default     = "intranet.example.com"
}

variable "okta_client_id" {
  description = "Okta OIDC client ID."
  type        = string
  default     = "0oa000000000000000"
}

variable "okta_client_secret" {
  description = "Okta OIDC client secret. Supply this from a secret store, never as a literal in version control."
  type        = string
  default     = "placeholder-not-a-real-secret"
  sensitive   = true
}

variable "okta_account_url" {
  description = "Okta account URL."
  type        = string
  default     = "https://example.okta.com"
}

variable "mtls_certificate_pem" {
  description = "PEM encoded root CA used for Access mutual TLS."
  type        = string
  default     = "-----BEGIN CERTIFICATE-----\nMIIBpDCCAUqgAwIBAgIURPLACEMENTONLYNOTAREALCERT=\n-----END CERTIFICATE-----\n"
}

variable "managed_network_sha256" {
  description = "SHA256 fingerprint of the TLS certificate presented by the managed network endpoint."
  type        = string
  default     = "b5bb9d8014a0f9b1d61e21e796d78dccdf1352f23cd32812f4850b878ae4944c"
}
