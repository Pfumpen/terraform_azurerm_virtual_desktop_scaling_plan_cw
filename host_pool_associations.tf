resource "time_sleep" "wait_for_rbac" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.avd_power_on_off_sub
  ]
}

resource "azurerm_virtual_desktop_scaling_plan_host_pool_association" "this" {
  for_each = var.host_pool_associations

  scaling_plan_id = azurerm_virtual_desktop_scaling_plan.this.id
  host_pool_id    = each.value.host_pool_id
  enabled         = each.value.enabled

  depends_on = [
    time_sleep.wait_for_rbac
  ]
}
