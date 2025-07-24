provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-avd-scaling-plan-complete"
  location = "westeurope"
}

# --- Dependencies ---
# Create two placeholder host pools for association
resource "azurerm_virtual_desktop_host_pool" "pool1" {
  name                = "hp-avd-pool1-complete"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
}

resource "azurerm_virtual_desktop_host_pool" "pool2" {
  name                = "hp-avd-pool2-complete"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  type                = "Pooled"
  load_balancer_type  = "DepthFirst"
}

# Create a Log Analytics Workspace for diagnostics
resource "azurerm_log_analytics_workspace" "this" {
  name                = "la-avd-diagnostics-complete"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --- Module Invocation ---
module "scaling_plan_complete" {
  source = "../.."

  name                = "sp-avd-complete-example"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  friendly_name       = "Complete AVD Scaling Plan"
  description         = "A comprehensive example of the AVD Scaling Plan module."
  time_zone           = "W. Europe Standard Time"
  exclusion_tag       = "No-Scaling"

  schedules = {
    weekdays = {
      days_of_week                       = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      ramp_up_start_time                 = "06:30"
      ramp_up_load_balancing_algorithm   = "BreadthFirst"
      ramp_up_minimum_hosts_percent      = 15
      ramp_up_capacity_threshold_percent = 85
      peak_start_time                    = "09:30"
      peak_load_balancing_algorithm      = "BreadthFirst"
      ramp_down_start_time               = "17:30"
      ramp_down_load_balancing_algorithm = "BreadthFirst"
      ramp_down_minimum_hosts_percent    = 10
      ramp_down_capacity_threshold_percent = 60
      ramp_down_force_logoff_users       = true
      ramp_down_wait_time_minutes        = 45
      ramp_down_notification_message     = "Your session will end in 45 minutes. Please save your work."
      ramp_down_stop_hosts_when          = "ZeroSessions"
      off_peak_start_time                = "23:00"
      off_peak_load_balancing_algorithm  = "BreadthFirst"
    },
    weekends = {
      days_of_week                       = ["Saturday", "Sunday"]
      ramp_up_start_time                 = "08:00"
      ramp_up_load_balancing_algorithm   = "DepthFirst"
      ramp_up_minimum_hosts_percent      = 5
      ramp_up_capacity_threshold_percent = 90
      peak_start_time                    = "10:00"
      peak_load_balancing_algorithm      = "DepthFirst"
      ramp_down_start_time               = "16:00"
      ramp_down_load_balancing_algorithm = "DepthFirst"
      ramp_down_minimum_hosts_percent    = 0
      ramp_down_capacity_threshold_percent = 70
      ramp_down_force_logoff_users       = true
      ramp_down_wait_time_minutes        = 15
      ramp_down_notification_message     = "This machine will be shut down in 15 minutes."
      ramp_down_stop_hosts_when          = "ZeroActiveSessions"
      off_peak_start_time                = "20:00"
      off_peak_load_balancing_algorithm  = "DepthFirst"
    }
  }

  host_pool_associations = {
    finance_pool = {
      host_pool_id = azurerm_virtual_desktop_host_pool.pool1.id
      enabled      = true
    },
    dev_pool = {
      host_pool_id = azurerm_virtual_desktop_host_pool.pool2.id
      enabled      = false # Disabled for maintenance
    }
  }

  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
    enabled_log_categories = [
      "ScalingPlanPooledHostPoolSchedule",
      "ScalingPlanPersonalHostPoolSchedule",
      "ScalingPlanVMMetrics"
    ]
    enabled_metric_categories = ["AllMetrics"]
  }

  role_assignments = {
    avd_contributor = {
      # In a real scenario, this would be a user or group object ID
      principal_id               = "00000000-0000-0000-0000-000000000000"
      role_definition_id_or_name = "Desktop Virtualization Power On Off Contributor"
    }
  }

  tags = {
    environment = "production"
    project     = "avd-scaling"
  }
}
