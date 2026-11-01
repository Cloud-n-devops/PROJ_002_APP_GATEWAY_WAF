resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}"
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "appgw_snet" {
  name                 = "snet-appgw-${var.project_name}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.app_gtw_snet_address_space
}

resource "azurerm_subnet" "backend_snet" {
  name                                      = "snet-backend-${var.project_name}"
  resource_group_name                       = var.resource_group_name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = var.backend_snet_address_space
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-appgw-prod-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard" # Must be Standard for App Gateway v2
}


# Create the Private DNS Zone (Must have this specific name)
resource "azurerm_private_dns_zone" "app_service_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group_name
}

# Link the DNS Zone to your VNet so the App Gateway can use it
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "vnet-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.app_service_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Create the A Record to map the App Name to the Private IP
resource "azurerm_private_dns_a_record" "app_service_a_record" {
  name                = var.webapp_name # Your app name
  zone_name           = azurerm_private_dns_zone.app_service_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = var.pdnsz_record_private_ip_address
}
