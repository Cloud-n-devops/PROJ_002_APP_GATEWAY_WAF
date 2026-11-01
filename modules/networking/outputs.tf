output "backend_snet_id" {
  value = azurerm_subnet.backend_snet.id
}
output "app_gtw_snet_id" {
  value = azurerm_subnet.appgw_snet.id
}
output "public_ip_id" {
  value = azurerm_public_ip.appgw_pip.id
}
output "public_ip_address" {
  value = azurerm_public_ip.appgw_pip.ip_address
}