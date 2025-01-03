module "oci" {
  source = "./modules/oci"

  ssh_public_key = var.ssh_public_key
  compartment_id = var.compartment_id
  region         = var.region
}

module "ingress" {
  source = "./modules/ingress"

  ingress_domain        = var.ingress_domain
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id

  depends_on = [module.oci]
}

module "clickhouse" {
  source = "./modules/clickhouse"

  depends_on = [module.oci, module.ingress]
}

module "metrics" {
  source = "./modules/metrics"

  ingress_domain = var.ingress_domain

  depends_on = [module.oci, module.ingress]
}
