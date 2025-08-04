#------------------------------------------------------------------------------
# General Variables
#------------------------------------------------------------------------------

variable "name" {
  type        = string
  description = "(Required) The name for the Virtual Desktop Scaling Plan. Must adhere to Azure naming conventions."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]$", var.name))
    error_message = "The scaling plan name must be between 3 and 63 characters, start and end with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the existing Resource Group where the scaling plan will be created."
}

variable "location" {
  type        = string
  description = "(Required) The Azure region for deployment. This is a preview feature and may only be available in specific regions."

}

variable "friendly_name" {
  type        = string
  description = "(Optional) A friendly name for the scaling plan."
  default     = null
}

variable "description" {
  type        = string
  description = "(Optional) A description for the scaling plan."
  default     = null
}

variable "time_zone" {
  type        = string
  description = "(Required) The IANA time zone name to be used by the scaling plan (e.g., 'W. Europe Standard Time')."
  # A comprehensive regex for all IANA time zones is impractical.
  # A simple check for structure is performed. The Azure API will perform the final validation.
  validation {
    condition     = can(regex("^[a-zA-Z_\\/\\s\\.\\(\\)-]+$", var.time_zone))
    error_message = "The time_zone must be a valid IANA time zone name."
  }
}

variable "exclusion_tag" {
  type        = string
  description = "(Optional) The name of the tag used to exclude VMs from scaling operations."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to apply to the scaling plan resource."
  default     = {}
}

#------------------------------------------------------------------------------
# Schedules Variable
#------------------------------------------------------------------------------

variable "schedules" {
  type = map(object({
    days_of_week = list(string)
    ramp_up_start_time = string
    ramp_up_load_balancing_algorithm = string
    ramp_up_minimum_hosts_percent = number
    ramp_up_capacity_threshold_percent = number
    peak_start_time = string
    peak_load_balancing_algorithm = string
    ramp_down_start_time = string
    ramp_down_load_balancing_algorithm = string
    ramp_down_minimum_hosts_percent = number
    ramp_down_capacity_threshold_percent = number
    ramp_down_force_logoff_users = bool
    ramp_down_wait_time_minutes = number
    ramp_down_notification_message = string
    ramp_down_stop_hosts_when = string
    off_peak_start_time = string
    off_peak_load_balancing_algorithm = string
  }))
  description = "(Required) A map of schedule configurations for the scaling plan. The map key is a logical name for the schedule (e.g., 'weekdays')."

  # --- Validation Rules for Schedules ---

  validation {
    condition = alltrue([
      for schedule in var.schedules : alltrue([
        for day in schedule.days_of_week : contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], day)
      ])
    ])
    error_message = "Invalid 'days_of_week'. Each day must be one of: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", schedule.ramp_up_start_time))
    ])
    error_message = "Invalid 'ramp_up_start_time'. Must be in HH:MM format (e.g., '08:00')."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", schedule.peak_start_time))
    ])
    error_message = "Invalid 'peak_start_time'. Must be in HH:MM format (e.g., '09:00')."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", schedule.ramp_down_start_time))
    ])
    error_message = "Invalid 'ramp_down_start_time'. Must be in HH:MM format (e.g., '18:00')."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", schedule.off_peak_start_time))
    ])
    error_message = "Invalid 'off_peak_start_time'. Must be in HH:MM format (e.g., '22:00')."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : contains(["BreadthFirst", "DepthFirst"], schedule.ramp_up_load_balancing_algorithm)
    ])
    error_message = "Invalid 'ramp_up_load_balancing_algorithm'. Must be 'BreadthFirst' or 'DepthFirst'."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : contains(["BreadthFirst", "DepthFirst"], schedule.peak_load_balancing_algorithm)
    ])
    error_message = "Invalid 'peak_load_balancing_algorithm'. Must be 'BreadthFirst' or 'DepthFirst'."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : contains(["BreadthFirst", "DepthFirst"], schedule.ramp_down_load_balancing_algorithm)
    ])
    error_message = "Invalid 'ramp_down_load_balancing_algorithm'. Must be 'BreadthFirst' or 'DepthFirst'."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : contains(["BreadthFirst", "DepthFirst"], schedule.off_peak_load_balancing_algorithm)
    ])
    error_message = "Invalid 'off_peak_load_balancing_algorithm'. Must be 'BreadthFirst' or 'DepthFirst'."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : schedule.ramp_up_minimum_hosts_percent >= 0 && schedule.ramp_up_minimum_hosts_percent <= 100
    ])
    error_message = "The 'ramp_up_minimum_hosts_percent' must be between 0 and 100."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : schedule.ramp_up_capacity_threshold_percent >= 1 && schedule.ramp_up_capacity_threshold_percent <= 100
    ])
    error_message = "The 'ramp_up_capacity_threshold_percent' must be between 1 and 100."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : schedule.ramp_down_minimum_hosts_percent >= 0 && schedule.ramp_down_minimum_hosts_percent <= 100
    ])
    error_message = "The 'ramp_down_minimum_hosts_percent' must be between 0 and 100."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : schedule.ramp_down_capacity_threshold_percent >= 1 && schedule.ramp_down_capacity_threshold_percent <= 100
    ])
    error_message = "The 'ramp_down_capacity_threshold_percent' must be between 1 and 100."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : contains(["ZeroSessions", "ZeroActiveSessions"], schedule.ramp_down_stop_hosts_when)
    ])
    error_message = "Invalid 'ramp_down_stop_hosts_when'. Must be 'ZeroSessions' or 'ZeroActiveSessions'."
  }
}

#------------------------------------------------------------------------------
# Host Pool Associations Variable
#------------------------------------------------------------------------------

variable "host_pool_associations" {
  type = map(object({
    host_pool_id = string
    enabled      = bool
  }))
  description = "(Optional) A map to associate host pools with this scaling plan. The map key is a logical name for the association."
  default     = {}

  validation {
    condition = alltrue([
      for assoc in var.host_pool_associations : can(regex("^/subscriptions/.+/resourceGroups/.+/providers/Microsoft.DesktopVirtualization/hostPools/.+$", assoc.host_pool_id))
    ])
    error_message = "Invalid 'host_pool_id'. Must be a valid Azure Resource ID for a Virtual Desktop Host Pool."
  }
}

#------------------------------------------------------------------------------
# Diagnostic Settings Variables
#------------------------------------------------------------------------------

variable "diagnostics_level" {
  description = "Defines the desired diagnostic intent. 'all' and 'audit' are dynamically mapped to available categories. Possible values: 'none', 'all', 'audit', 'custom'."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "all", "audit", "custom"], var.diagnostics_level)
    error_message = "Valid values for diagnostics_level are 'none', 'all', 'audit', or 'custom'."
  }
}

variable "diagnostic_settings" {
  description = "A map containing the destination IDs for diagnostic settings. When diagnostics are enabled, exactly one destination must be specified."
  type = object({
    log_analytics_workspace_id     = optional(string)
    eventhub_authorization_rule_id = optional(string)
    storage_account_id             = optional(string)
  })
  default = {}

  validation {
    condition = var.diagnostics_level == "none" || (
      (try(var.diagnostic_settings.log_analytics_workspace_id, null) != null ? 1 : 0) +
      (try(var.diagnostic_settings.eventhub_authorization_rule_id, null) != null ? 1 : 0) +
      (try(var.diagnostic_settings.storage_account_id, null) != null ? 1 : 0) == 1
    )
    error_message = "When 'diagnostics_level' is not 'none', exactly one of 'log_analytics_workspace_id', 'eventhub_authorization_rule_id', or 'storage_account_id' must be specified in the 'diagnostic_settings' object."
  }
}

variable "diagnostics_custom_logs" {
  description = "A list of log categories to enable when diagnostics_level is 'custom'."
  type        = list(string)
  default     = []
}

variable "diagnostics_custom_metrics" {
  description = "A list of specific metric categories to enable. Use ['AllMetrics'] for all."
  type        = list(string)
  default     = ["AllMetrics"]
}

#------------------------------------------------------------------------------
# RBAC / Role Assignments Variable
#------------------------------------------------------------------------------

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name = string
    principal_id               = string
    description                = optional(string)
    condition                  = optional(string)
    condition_version          = optional(string)
  }))
  description = "(Optional) A map of role assignments to create on the scaling plan's scope. The map key is a logical name for the assignment."
  default     = {}

  validation {
    condition = alltrue([
      for ra in var.role_assignments : ra.principal_id != null && ra.role_definition_id_or_name != null
    ])
    error_message = "Both 'principal_id' and 'role_definition_id_or_name' must be specified for each role assignment."
  }
}
