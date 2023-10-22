terraform {
  # Azure Provider source and version being used
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Configure Random Interger resource
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create resource group with random integer in the name
resource "azurerm_resource_group" "softunibazar_rg" {
  name     = "${var.resource_group_name}${random_integer.ri.result}"
  location = var.resource_group_location
}

# Configure Azure Service Plan
resource "azurerm_service_plan" "softunibazar_azure_sp" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.softunibazar_rg.name
  location            = azurerm_resource_group.softunibazar_rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# Configure Azure Linux Web App
resource "azurerm_linux_web_app" "softunibazar_wa" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.softunibazar_rg.name
  location            = azurerm_service_plan.softunibazar_azure_sp.location
  service_plan_id     = azurerm_service_plan.softunibazar_azure_sp.id
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.softunibazar_mssqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.softunibazar_database.name};User ID=${azurerm_mssql_server.softunibazar_mssqlserver.administrator_login};Password=${azurerm_mssql_server.softunibazar_mssqlserver.administrator_login_password};MultipleActiveResultSets=True;Trusted_Connection=False;"
  }

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
}

# Configure Azure Service App Source Control
resource "azurerm_app_service_source_control" "softunibazar_ssc" {
  app_id                 = azurerm_linux_web_app.softunibazar_wa.id
  repo_url               = var.repo_URL
  branch                 = "main"
  use_manual_integration = true
}

# Configure Azure Storage Account
resource "azurerm_storage_account" "softunibazar_storage_acc" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.softunibazar_rg.name
  location                 = azurerm_resource_group.softunibazar_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Configure MSSQL Server
resource "azurerm_mssql_server" "softunibazar_mssqlserver" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.softunibazar_rg.name
  location                     = azurerm_resource_group.softunibazar_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_administrator_login_username
  administrator_login_password = var.sql_administrator_password
  minimum_tls_version          = "1.2"

  tags = {
    environment = "production"
  }
}

# Configure MSSQL Database
resource "azurerm_mssql_database" "softunibazar_database" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.softunibazar_mssqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  read_scale     = false
  sku_name       = "S0"
  zone_redundant = false

  tags = {
    environment = "production"
  }
}

# Configure Firewall Rule
resource "azurerm_mssql_firewall_rule" "softunibazar_firewall_rule" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.softunibazar_mssqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
