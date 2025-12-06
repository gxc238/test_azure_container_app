import {
  to = azurerm_resource_group.rg
  id = "/subscriptions/c17137a4-ecb2-48fe-8c4f-3a597bdcceaf/resourceGroups/gxc238-sb-rg"
}

import {
  to = azurerm_virtual_network.vnet
  id = "/subscriptions/c17137a4-ecb2-48fe-8c4f-3a597bdcceaf/resourceGroups/gxc238-sb-rg/providers/Microsoft.Network/virtualNetworks/gxc238-sb-009-vnet"
}

import {
  to = azurerm_subnet.subnet
  id = "/subscriptions/c17137a4-ecb2-48fe-8c4f-3a597bdcceaf/resourceGroups/gxc238-sb-rg/providers/Microsoft.Network/virtualNetworks/gxc238-sb-009-vnet/subnets/default"
}



# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "gxc238-sb-rg"
  location = "eastus2"
  
  tags = {
    Application = "Shared Cloud Services"
    CostCenter  = "D140-84IM64"
    Department  = "I&O Transformation"
    Division    = "Corp"
    Environment = "SBLive"
    Owner       = "Mike Conrad | mike.conrad@sherwin.com"
    Program     = "Cloud Platforms"
    Project     = "Cloud Platforms"
    Team        = "Cloud Platforms"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "gxc238-sb-009-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.156.202.0/23", "10.156.1.96/28"]
  
  tags = {
    Application = "Shared Cloud Services"
    CostCenter  = "D140-84IM64"
    Department  = "I&O Transformation"
    Division    = "Corp"
    Environment = "SBLive"
    Owner       = "Mike Conrad | mike.conrad@sherwin.com"
    Program     = "Cloud Platforms"
    Project     = "Cloud Platforms"
    Team        = "Cloud Platforms"
  }
}

# Subnet for Container Apps Environment
resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.156.202.0/23"]
  
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Subnet for Private Endpoint
resource "azurerm_subnet" "pe_subnet" {
  name                 = "privateendpoint-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.156.1.96/28"]
}

# Container Apps Environment with VNET Integration
resource "azurerm_container_app_environment" "env" {
  name                = "gxc238-containerapp-test-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  internal_load_balancer_enabled = true
  public_network_access          = "Disabled"
  infrastructure_subnet_id       = azurerm_subnet.subnet.id
  
  # No Log Analytics workspace - using default logging
  logs_destination = ""
  
  tags = {
    Application = "Shared Cloud Services"
    CostCenter  = "D140-84IM64"
    Department  = "I&O Transformation"
    Division    = "Corp"
    Environment = "SBLive"
    Owner       = "Mike Conrad | mike.conrad@sherwin.com"
    Program     = "Cloud Platforms"
    Project     = "Cloud Platforms"
    Team        = "Cloud Platforms"
  }
}

# Container App
resource "azurerm_container_app" "test_app" {
  name                = "gxc238-cus-test-container-app"
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





# Data source to reference existing private DNS zone in different subscription
data "azurerm_private_dns_zone" "containerapp_dns_zone" {
  name                = "privatelink.eastus2.azurecontainerapps.io"
  resource_group_name = "shared_private_dns_zones_rg"
  provider            = azurerm.dns_subscription
}

# Private Endpoint for Container App Environment
resource "azurerm_private_endpoint" "containerapp_pe" {
  name                = "pe-containerapp-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "psc-containerapp-env"
    private_connection_resource_id = azurerm_container_app_environment.env.id
    subresource_names              = ["managedEnvironments"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.containerapp_dns_zone.id]
  }

  tags = {
    Application = "Shared Cloud Services"
    CostCenter  = "D140-84IM64"
    Department  = "I&O Transformation"
    Division    = "Corp"
    Environment = "SBLive"
    Owner       = "Mike Conrad | mike.conrad@sherwin.com"
    Program     = "Cloud Platforms"
    Project     = "Cloud Platforms"
    Team        = "Cloud Platforms"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink" {
  name                  = "dnslink"
  resource_group_name   = data.azurerm_private_dns_zone.containerapp_dns_zone.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.containerapp_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  provider              = azurerm.dns_subscription
}