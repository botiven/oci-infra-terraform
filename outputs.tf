output "clickhouse_password" {
  value     = module.clickhouse.clickhouse_password
  sensitive = true
}

output "grafana_password" {
  value     = module.metrics.grafana_password
  sensitive = true
}
