provider "azurerm" {
  features {}

  tenant_id       = var.azure_tenant_id
  client_id       = var.azure_user_name
  client_secret   = var.azure_password
  subscription_id = var.azure-subscription
}


