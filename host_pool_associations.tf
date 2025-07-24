resource "azurerm_virtual_desktop_scaling_plan_host_pool_association" "this" {
  for_each = var.host_pool_associations

  scaling_plan_id     = azurerm_virtual_desktop_scaling_plan.this.id
  host_pool_id        = each.value.host_pool_id
  enabled             = each.value.enabled
}
