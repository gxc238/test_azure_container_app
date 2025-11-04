# providers.tf
# Resource definitions for providers
 
terraform {
  required_providers {
    azurerm = {
      version = ">=4.8.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=3.0.2"
    }
  }
}
# Configure the Microsoft Azure Resource Manager provider
provider "azurerm" {
  features {}
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
}