output "id" {
  description = "The resource ID of the created Virtual Desktop Scaling Plan."
  value       = azurerm_virtual_desktop_scaling_plan.this.id
}

output "name" {
  description = "The name of the Virtual Desktop Scaling Plan."
  value       = azurerm_virtual_desktop_scaling_plan.this.name
}

output "host_pool_association_ids" {
  description = "A map of the resource IDs for the created host pool associations, with the logical map key as the key."
  value = {
    for k, v in azurerm_virtual_desktop_scaling_plan_host_pool_association.this : k => v.id
  }
}

output "diagnostic_setting_id" {
  description = "The ID of the created diagnostic setting, if enabled."
  value       = try(azurerm_monitor_diagnostic_setting.this[0].id, null)
}
