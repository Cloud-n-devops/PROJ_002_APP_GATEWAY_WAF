variable "resource_group_name" {
  type        = string      
}   
variable "location" {
  type = string      
}
variable "project_name" {
  type = string
}


variable "vnet_address_space" {
  type = any      
}
variable "app_gtw_snet_address_space" {
  type = any
}
variable "backend_snet_address_space" {
  type = any
}

variable "pdnsz_record_private_ip_address" {
  type = list(string)
  description = "Private IP address to be added as an A record in Private DNS zone"
}
variable "webapp_name" {
  type = string
}