variable "subscription_id" {
  description = "ID de la souscription Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nom du Resource Group"
  type        = string
  default     = "rg-brief331"
}

variable "location" {
  description = "Region Azure"
  type        = string
  default     = "France Central"
}

variable "postgres_server_name" {
  description = "Nom du serveur PostgreSQL"
  type        = string
  default     = "psql-brief331-rnz"
}

variable "postgres_admin_user" {
  description = "Login administrateur PostgreSQL"
  type        = string
  sensitive   = true
}

variable "postgres_admin_password" {
  description = "Mot de passe administrateur PostgreSQL"
  type        = string
  sensitive   = true
}

variable "planka_secret_key" {
  description = "Cle secrete pour Planka"
  type        = string
  sensitive   = true
}

variable "planka_admin_email" {
  description = "Email de l administrateur Planka"
  type        = string
}

variable "planka_admin_password" {
  description = "Mot de passe administrateur Planka"
  type        = string
  sensitive   = true
}
