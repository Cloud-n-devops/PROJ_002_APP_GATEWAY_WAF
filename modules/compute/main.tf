locals {
  frontend_port_name = "http-port"
  frontend_ip_name = "frontend-ip"
  backend_address_pool_name = "webapp-backend"
  backend_http_settings_name = "http-settings"
  protocol = "Http"


}
#  App Service Plan with Elastic Scale
resource "azurerm_service_plan" "plan" {
  name                = "asp-webapp-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "P1v2" # Required for Private Link
  worker_count        = 2      # Minimum instance count for HA
}

# The Web App
resource "azurerm_linux_web_app" "app" {
  name                          = var.webapp_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  service_plan_id               = azurerm_service_plan.plan.id
  public_network_access_enabled = false # Strict Security

  site_config {
    always_on = true
    application_stack {
      php_version = "8.2" # Example stack
    }
  }
}


resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-config"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.plan.id

  profile {
    name = "default"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}

#  Application Gateway with WAF
resource "azurerm_application_gateway" "main" {
  name                = "appgw-prod-${var.project_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.policy_waf.id

  # Inline WAF configuration for simplicity. For production, use a separate WAF policy resource.
  # waf_configuration {
  #   enabled          = true
  #   firewall_mode    = "Prevention"
  #   rule_set_type    = "OWASP"
  #   rule_set_version = "3.2"
  # }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration-${var.project_name}"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_name
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = [azurerm_linux_web_app.app.default_hostname]
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = local.protocol
    request_timeout       = 60
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = local.frontend_ip_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = local.protocol
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "listener"
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
    priority                   = 1
  }
}

# switch between inline WAF config and separate WAF policy
resource "azurerm_web_application_firewall_policy" "policy_waf" {
  name                = "waf-policy-elara"
  resource_group_name = var.resource_group_name
  location            = var.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled = true
    mode    = "Detection" # Change to "Detection" for initial testing
  }
}
