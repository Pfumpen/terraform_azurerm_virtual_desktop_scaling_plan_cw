provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-scaling-plan-basic-example"
  location = "westeurope"
}

# This module assumes a host pool already exists.
# For the example, we create a placeholder one.
resource "azurerm_virtual_desktop_host_pool" "example" {
  name                = "hp-avd-basic-example"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
}

module "scaling_plan" {
  source = "../.."

  name                = "sp-avd-basic-example"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  time_zone           = "W. Europe Standard Time"

  schedules = {
    weekdays = {
      days_of_week                       = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      ramp_up_start_time                 = "06:00"
      ramp_up_load_balancing_algorithm   = "BreadthFirst"
      ramp_up_minimum_hosts_percent      = 10
      ramp_up_capacity_threshold_percent = 80
      peak_start_time                    = "09:00"
      peak_load_balancing_algorithm      = "BreadthFirst"
      ramp_down_start_time               = "18:00"
      ramp_down_load_balancing_algorithm = "BreadthFirst"
      ramp_down_minimum_hosts_percent    = 5
      ramp_down_capacity_threshold_percent = 50
      ramp_down_force_logoff_users       = true
      ramp_down_wait_time_minutes        = 30
      ramp_down_notification_message     = "Please save your work. You will be logged off in 30 minutes."
      ramp_down_stop_hosts_when          = "ZeroSessions"
      off_peak_start_time                = "22:00"
      off_peak_load_balancing_algorithm  = "BreadthFirst"
    }
  }

  host_pool_associations = {
    main_pool = {
      host_pool_id = azurerm_virtual_desktop_host_pool.example.id
      enabled      = true
    }
  }

  tags = {
    environment = "example"
    cost_center = "it"
  }
}
