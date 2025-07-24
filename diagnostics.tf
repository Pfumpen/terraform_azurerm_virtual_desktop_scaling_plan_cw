resource "azurerm_monitor_diagnostic_setting" "this" {
  count = try(var.diagnostic_settings.enabled, false) ? 1 : 0

  name                           = var.diagnostic_settings.name != null ? var.diagnostic_settings.name : "diag-${var.name}"
  target_resource_id             = azurerm_virtual_desktop_scaling_plan.this.id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)

  dynamic "enabled_log" {
    for_each = try(var.diagnostic_settings.log_categories, [])
    content {
      category = log.value
    }
  }

  dynamic "metric" {
    for_each = try(var.diagnostic_settings.metric_categories, [])
    content {
      category = metric.value
      enabled  = true
    }
  }
}
