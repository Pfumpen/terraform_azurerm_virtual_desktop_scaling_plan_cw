# locals are used to calculate the diagnostic settings based on the user's intent.
# This approach avoids validation errors when diagnostics are disabled, as the data source output is only accessed when enabled.

locals {
  # A single boolean flag to control all diagnostic resources.
  global_diagnostics_enabled = var.diagnostics_level != "none"

  # Securely captures the data source output. This local will be `null` if diagnostics are disabled.
  # This prevents errors from trying to access a non-existent data source.
  data_source_output = local.global_diagnostics_enabled ? data.azurerm_monitor_diagnostic_categories.this[0] : null

  # --- Pre-calculated Lists for the Resource Block ---
  # These locals translate the high-level 'diagnostics_level' intent into specific category lists for the resource.

  # Determines active log category GROUPS ('allLogs', 'audit').
  # These are used when the resource supports them and the intent matches.
  active_log_groups = local.global_diagnostics_enabled && var.diagnostics_level == "all" && contains(try(local.data_source_output.log_category_groups, []), "allLogs") ? ["allLogs"] : (
    local.global_diagnostics_enabled && var.diagnostics_level == "audit" && contains(try(local.data_source_output.log_category_groups, []), "audit") ? ["audit"] : []
  )

  # Determines active INDIVIDUAL logs.
  # This is used for 'custom' level, or as a fallback for 'all' if 'allLogs' group is not supported.
  active_individual_logs = local.global_diagnostics_enabled && var.diagnostics_level == "custom" ? var.diagnostics_custom_logs : (
    local.global_diagnostics_enabled && var.diagnostics_level == "all" && !contains(try(local.data_source_output.log_category_groups, []), "allLogs") ? try(local.data_source_output.logs, []) : []
  )

  # Determines active metrics. This is enabled only if the resource actually supports metrics.
  active_metrics = local.global_diagnostics_enabled && length(try(local.data_source_output.metrics, [])) > 0 ? var.diagnostics_custom_metrics : []
}

# This data source discovers the available diagnostic categories for the target resource at runtime.
# It is only executed when diagnostics are enabled, preventing unnecessary API calls.
data "azurerm_monitor_diagnostic_categories" "this" {
  count = local.global_diagnostics_enabled ? 1 : 0

  # The resource_id is the ID of the primary resource created by this module.
  resource_id = azurerm_virtual_desktop_scaling_plan.this.id
}

# This resource creates the diagnostic setting in Azure.
# It is only created when diagnostics are enabled.
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = local.global_diagnostics_enabled ? 1 : 0

  # A unique name for the diagnostic setting resource.
  name                           = "diag-${var.name}"
  target_resource_id             = data.azurerm_monitor_diagnostic_categories.this[0].resource_id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  # The dynamic blocks below consume the pre-calculated lists from the locals block.
  # This creates a clean and readable resource definition.

  # Enables log category groups like 'allLogs' or 'audit'.
  dynamic "enabled_log" {
    for_each = toset(local.active_log_groups)
    content {
      category_group = enabled_log.value
    }
  }

  # Enables individual log categories for 'custom' or 'all' (fallback).
  dynamic "enabled_log" {
    for_each = toset(local.active_individual_logs)
    content {
      category = enabled_log.value
    }
  }

  # Enables metric categories.
  dynamic "metric" {
    for_each = toset(local.active_metrics)
    content {
      category = metric.value
    }
  }
}
