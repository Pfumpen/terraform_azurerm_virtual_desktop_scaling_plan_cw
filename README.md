# Terraform Azure Virtual Desktop Scaling Plan Module

This Terraform module provisions an Azure Virtual Desktop (AVD) Scaling Plan. It provides a comprehensive set of features for configuring scaling schedules, associating host pools, and managing diagnostics and role-based access control (RBAC).

## Features

*   Provisions an AVD Scaling Plan with detailed scheduling options.
*   Supports multiple, distinct schedules for different times (e.g., weekdays, weekends).
*   Allows for the association of multiple host pools to the scaling plan.
*   Integrates with Azure Monitor to configure diagnostic settings for logs and metrics.
*   Provides a flexible way to configure RBAC by creating role assignments on the scaling plan's scope.

## Limitations and Important Notes

*   The AVD Scaling Plan is an Azure preview feature. Its availability may be limited to specific regions, and its behavior may change.
*   This module does not create the dependent resources such as the Resource Group, Host Pools, or diagnostic sinks (Log Analytics Workspace, etc.). These must exist prior to using this module.

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.0.0 |
| azurerm   | >= 3.0.0 |

## External Dependencies

This module relies on the following external resources, which you must provide via input variables:

*   **Resource Group:** An existing Azure Resource Group where the scaling plan will be deployed (`var.resource_group_name`).
*   **Virtual Desktop Host Pools:** Existing AVD Host Pools to be associated with the scaling plan (`var.host_pool_associations`).
*   **Diagnostic Sinks (Optional):** An existing Log Analytics Workspace, Event Hub, or Storage Account if diagnostics are enabled (`var.diagnostic_settings`).
*   **RBAC Principals (Optional):** Existing Azure AD principals (users, groups, service principals) to be granted roles (`var.role_assignments`).

## Resources Created

| Type                                                         | Name |
|--------------------------------------------------------------|------|
| `azurerm_virtual_desktop_scaling_plan`                       | `this` |
| `azurerm_virtual_desktop_scaling_plan_host_pool_association` | `this` (for_each) |
| `azurerm_monitor_diagnostic_setting`                         | `this` (optional) |
| `azurerm_role_assignment`                                    | `this` (for_each) |

## Input Variables

| Name                  | Description                                                                                             | Type        | Default | Required |
|-----------------------|---------------------------------------------------------------------------------------------------------|-------------|---------|----------|
| `name`                | The name for the Virtual Desktop Scaling Plan. Must adhere to Azure naming conventions.                 | `string`    | n/a     | yes      |
| `resource_group_name` | The name of the existing Resource Group where the scaling plan will be created.                         | `string`    | n/a     | yes      |
| `location`            | The Azure region for deployment. This is a preview feature and may only be available in specific regions. | `string`    | n/a     | yes      |
| `friendly_name`       | A friendly name for the scaling plan.                                                                   | `string`    | `null`  | no       |
| `description`         | A description for the scaling plan.                                                                     | `string`    | `null`  | no       |
| `time_zone`           | The IANA time zone name to be used by the scaling plan (e.g., 'W. Europe Standard Time').                | `string`    | n/a     | yes      |
| `exclusion_tag`       | The name of the tag used to exclude VMs from scaling operations.                                        | `string`    | `null`  | no       |
| `tags`                | A map of tags to apply to the scaling plan resource.                                                    | `map(string)` | `{}`    | no       |
| `schedules`           | A map of schedule configurations for the scaling plan (see structure below).                            | `map(object)` | n/a     | yes      |
| `host_pool_associations` | A map to associate host pools with this scaling plan (see structure below).                            | `map(object)` | `{}`    | no       |
| `diagnostic_settings` | An object to configure diagnostic settings for the scaling plan (see structure below).                  | `object`    | `null`  | no       |
| `role_assignments`    | A map of role assignments to create on the scaling plan's scope (see structure below).                  | `map(object)` | `{}`    | no       |

---

### `schedules`

This variable defines the core scaling schedules. The map key is a logical name for the schedule (e.g., "weekdays").

**Type:**
```hcl
map(object({
  days_of_week                       = list(string)
  ramp_up_start_time                 = string
  ramp_up_load_balancing_algorithm   = string
  ramp_up_minimum_hosts_percent      = number
  ramp_up_capacity_threshold_percent = number
  peak_start_time                    = string
  peak_load_balancing_algorithm      = string
  ramp_down_start_time               = string
  ramp_down_load_balancing_algorithm = string
  ramp_down_minimum_hosts_percent    = number
  ramp_down_capacity_threshold_percent = number
  ramp_down_force_logoff_users       = bool
  ramp_down_wait_time_minutes        = number
  ramp_down_notification_message     = string
  ramp_down_stop_hosts_when          = string
  off_peak_start_time                = string
  off_peak_load_balancing_algorithm  = string
}))
```

**Example:**
```hcl
schedules = {
  "weekdays" = {
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
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users       = true
    ramp_down_wait_time_minutes        = 30
    ramp_down_notification_message     = "Please save your work. Your session will be logged off in 30 minutes."
    ramp_down_stop_hosts_when          = "ZeroSessions"
    off_peak_start_time                = "22:00"
    off_peak_load_balancing_algorithm  = "BreadthFirst"
  }
}
```

---

### `host_pool_associations`

This variable links existing AVD Host Pools to the scaling plan. The map key is a logical name for the association.

**Type:**
```hcl
map(object({
  host_pool_id = string
  enabled      = bool
}))
```

**Example:**
```hcl
host_pool_associations = {
  "finance_dept_pool" = {
    host_pool_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-avd-rg/providers/Microsoft.DesktopVirtualization/hostPools/hp-finance"
    enabled      = true
  }
}
```

---

### `diagnostic_settings`

This variable configures the diagnostic settings to send logs and metrics to a specified destination.

**Type:**
```hcl
object({
  enabled                       = optional(bool, true)
  name                          = optional(string, "diag-${var.name}")
  log_analytics_workspace_id    = optional(string)
  eventhub_authorization_rule_id = optional(string)
  storage_account_id            = optional(string)
  enabled_log_categories        = optional(list(string), [])
  enabled_metric_categories     = optional(list(string), ["AllMetrics"])
})
```

**Example:**
```hcl
diagnostic_settings = {
  name                       = "diag-avd-scaling-plan"
  log_analytics_workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-logging-rg/providers/Microsoft.OperationalInsights/workspaces/my-log-analytics"
  enabled_log_categories     = ["ScalingPlanPooledHostUsage"]
  enabled_metric_categories  = ["AllMetrics"]
}
```

---

### `role_assignments`

This variable creates role assignments on the scaling plan's scope. The map key is a logical name for the assignment.

**Type:**
```hcl
map(object({
  role_definition_id_or_name = string
  principal_id               = string
  description                = optional(string)
  condition                  = optional(string)
  condition_version          = optional(string)
}))
```

**Example:**
```hcl
role_assignments = {
  "avd_admin_reader_role" = {
    role_definition_id_or_name = "Reader"
    principal_id               = "11111111-1111-1111-1111-111111111111" # Object ID of the AVD Admin Group
    description                = "Allow AVD Admins to view this scaling plan."
  }
}
```

## Outputs

| Name                        | Description                                                                                    | Sensitive |
|-----------------------------|------------------------------------------------------------------------------------------------|-----------|
| `id`                        | The resource ID of the created Virtual Desktop Scaling Plan.                                   | false     |
| `name`                      | The name of the Virtual Desktop Scaling Plan.                                                  | false     |
| `host_pool_association_ids` | A map of the resource IDs for the created host pool associations, with the logical map key as the key. | false     |
| `diagnostic_setting_id`     | The ID of the created diagnostic setting, if enabled.                                          | false     |

## Usage Examples

### Basic Example

This example shows how to create a minimal scaling plan. You can find the full code in the `examples/basic` directory.

```hcl
module "avd_scaling_plan_basic" {
  source = "git::https/github.com/Pfumpen/terraform_azurerm_virtual_desktop_scaling_plan_cw.git"

  name                = "avdsp-basic-example"
  resource_group_name = "rg-avd-resources"
  location            = "westeurope"
  time_zone           = "W. Europe Standard Time"

  schedules = {
    "default" = {
      days_of_week                       = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      ramp_up_start_time                 = "07:00"
      ramp_up_load_balancing_algorithm   = "BreadthFirst"
      ramp_up_minimum_hosts_percent      = 10
      ramp_up_capacity_threshold_percent = 85
      peak_start_time                    = "09:00"
      peak_load_balancing_algorithm      = "BreadthFirst"
      ramp_down_start_time               = "17:00"
      ramp_down_load_balancing_algorithm = "BreadthFirst"
      ramp_down_minimum_hosts_percent    = 5
      ramp_down_capacity_threshold_percent = 90
      ramp_down_force_logoff_users       = true
      ramp_down_wait_time_minutes        = 15
      ramp_down_notification_message     = "Please save your work."
      ramp_down_stop_hosts_when          = "ZeroSessions"
      off_peak_start_time                = "20:00"
      off_peak_load_balancing_algorithm  = "BreadthFirst"
    }
  }

  tags = {
    environment = "production"
    cost_center = "IT-123"
  }
}
```

### Complete Example

For a comprehensive example that demonstrates all available variables, please see the code in the `examples/complete` directory. This example serves as a reference for all possible configurations.
