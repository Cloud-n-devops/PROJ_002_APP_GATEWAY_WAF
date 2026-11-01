terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20" 
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    application_insights {
      # This prevents the "Failure Anomalies" rule and 
      # its Action Group from being created automatically.
      disable_generated_rule = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
   }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "RG_app_gtw_waf" {
    name = "RG-${var.project_name}"
    location = var.location
}

#  Private Endpoint (Limits access to VNet)
resource "azurerm_private_endpoint" "pe" {
  name                = "pe-webapp-${var.project_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.RG_app_gtw_waf.name
  subnet_id           = module.networking.backend_snet_id

  private_service_connection {
    name                           = "psc-webapp-${var.project_name}"
    private_connection_resource_id = module.compute.webapp_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
}


module "networking" {
  source = "./modules/networking"
  resource_group_name = azurerm_resource_group.RG_app_gtw_waf.name
  location = azurerm_resource_group.RG_app_gtw_waf.location
  webapp_name = var.webapp_name
  vnet_address_space = var.address_space.vnet_address_space
  app_gtw_snet_address_space = var.address_space.subnets.app_gtw_subnet_address_prefix
  backend_snet_address_space = var.address_space.subnets.backend_subnet_address_prefix
  project_name = var.project_name
  pdnsz_record_private_ip_address = [azurerm_private_endpoint.pe.private_service_connection[0].private_ip_address]
}
module "compute" {
  source = "./modules/compute"
   project_name = var.project_name   
  resource_group_name = azurerm_resource_group.RG_app_gtw_waf.name
  location = azurerm_resource_group.RG_app_gtw_waf.location
  backend_subnet_id = module.networking.backend_snet_id
  appgw_subnet_id = module.networking.app_gtw_snet_id
  public_ip_id = module.networking.public_ip_id
  webapp_name = var.webapp_name
}