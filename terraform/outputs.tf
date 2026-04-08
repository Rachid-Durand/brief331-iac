output "planka_url" {
  description = "URL de Planka"
  value       = "https://${azurerm_container_app.planka.ingress[0].fqdn}"
}

output "postgres_fqdn" {
  description = "FQDN du serveur PostgreSQL"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "resource_group" {
  description = "Nom du Resource Group"
  value       = azurerm_resource_group.rg.name
}
