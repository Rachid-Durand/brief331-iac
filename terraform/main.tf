terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-brief331"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Sous-reseau pour Container Apps
resource "azurerm_subnet" "container_subnet" {
  name                 = "subnet-containers"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/23"]
  delegation {
    name = "container-delegation"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
# Sous-reseau pour PostgreSQL
resource "azurerm_subnet" "db_subnet" {
  name                 = "subnet-database"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
  delegation {
    name = "db-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
# DNS Zone privee pour PostgreSQL
resource "azurerm_private_dns_zone" "postgres_dns" {
  name                = "brief331.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "dns-link-brief331"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dns.name
  resource_group_name   = azurerm_resource_group.rg.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                          = var.postgres_server_name
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "16"
  delegated_subnet_id           = azurerm_subnet.db_subnet.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres_dns.id
  public_network_access_enabled = false
  administrator_login           = var.postgres_admin_user
  administrator_password        = var.postgres_admin_password
  storage_mb                    = 32768
  sku_name                      = "B_Standard_B1ms"
  zone                          = "1"
  depends_on = [azurerm_private_dns_zone_virtual_network_link.dns_link]
}
# Base de donnees Planka
resource "azurerm_postgresql_flexible_server_database" "planka_db" {
  name      = "planka"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
# Log Analytics Workspace (requis pour Container App Environment)
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "logs-brief331"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-brief331"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  infrastructure_subnet_id   = azurerm_subnet.container_subnet.id
}
# Container App Planka
resource "azurerm_container_app" "planka" {
  name                         = "planka-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  template {
    min_replicas = 1
    max_replicas = 1
    container {
      name   = "planka"
      image  = "ghcr.io/plankanban/planka:latest"
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${var.postgres_admin_user}:${var.postgres_admin_password}@${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/planka?sslmode=require"
      }
      env {
        name  = "BASE_URL"
        value = "https://planka-app.${azurerm_container_app_environment.env.default_domain}"
      }
      env {
        name  = "SECRET_KEY"
        value = var.planka_secret_key
      }
      env {
        name  = "DEFAULT_ADMIN_EMAIL"
        value = var.planka_admin_email
      }
      env {
        name  = "DEFAULT_ADMIN_PASSWORD"
        value = var.planka_admin_password
      }
      env {
        name  = "DEFAULT_ADMIN_NAME"
        value = "Admin"
      }
      env {
        name  = "DEFAULT_ADMIN_USERNAME"
        value = "admin"
      }
    }
  }
  ingress {
    external_enabled = true
    target_port      = 1337
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}
