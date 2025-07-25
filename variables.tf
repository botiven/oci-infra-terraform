variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to provision the resources in"
}

variable "ssh_public_key" {
  type        = string
  description = "The public key to be used for SSH access"
}

variable "ingress_domain" {
  type        = string
  description = "The domain to be used for ingress"
}

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "The Cloudflare API token"
}

variable "cloudflare_account_id" {
  type        = string
  description = "The Cloudflare account ID"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "The Cloudflare zone ID"
}
