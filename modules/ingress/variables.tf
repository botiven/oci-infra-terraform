variable "ingress_domain" {
  type        = string
  description = "The domain name to use for the ingress controller"
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
