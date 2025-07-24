resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_virtual_desktop_scaling_plan.this.id
  role_definition_name = each.value.role_definition_id_or_name
  principal_id         = each.value.principal_id
  description          = try(each.value.description, null)
  condition            = try(each.value.condition, null)
  condition_version    = try(each.value.condition_version, null)
}
