provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "gxc238-sb-rg"
  location = "eastus2"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "gxc238-sb-009-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.156.2.176/28"]
}

# Subnet for Container Apps Environment
resource "azurerm_subnet" "subnet" {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.156.2.176/28"]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

# Container Apps Environment with VNET Integration
resource "azurerm_container_app_environment" "env" {
  name                = "gxc238-container-test-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  internal_load_balancer_enabled = true
  infrastructure_subnet_id       = azurerm_subnet.subnet.id
}

# Container App
resource "azurerm_container_app" "app" {
  name                = "gxc238-test-container-app"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name = azurerm_resource_group.rg.name
  revision_mode       = "Single"

  template {
    container {
      name   = "myapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }

  ingress {
    external_enabled = false # Internal only
    target_port      = 80
    
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}