#------------------------------------------------------------------------------
# Diagnostic Settings
#------------------------------------------------------------------------------

locals {
  # Defines the diagnostic presets for the Virtual Desktop Scaling Plan.
  # The only available log category is "Autoscale". There are no metrics available.
  diagnostics_presets = {
    basic  = { logs = ["Autoscale"], metrics = [] },
    custom = { logs = var.diagnostics_custom_logs, metrics = var.diagnostics_custom_metrics }
  }

  # Determines the active log and metric categories based on the selected diagnostics_level.
  active_log_categories    = lookup(local.diagnostics_presets, var.diagnostics_level, { logs = [] }).logs
  active_metric_categories = lookup(local.diagnostics_presets, var.diagnostics_level, { metrics = [] }).metrics

  # A global switch to enable or disable the creation of the diagnostic setting resource.
  global_diagnostics_enabled = var.diagnostics_level != "none"
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  # Create the resource only if diagnostics are not set to 'none'.
  count = local.global_diagnostics_enabled ? 1 : 0

  name                           = "diag-${var.name}"
  target_resource_id             = azurerm_virtual_desktop_scaling_plan.this.id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  # Dynamically set the log categories to be enabled.
  dynamic "enabled_log" {
    for_each = toset(local.active_log_categories)
    content {
      category = enabled_log.value
    }
  }

  # Dynamically set the metric categories to be enabled.
  # Note: For this resource, there are no metrics, so this will typically be empty.
  dynamic "enabled_metric" {
    for_each = toset(local.active_metric_categories)
    content {
      category = enabled_metric.value
    }
  }
}
