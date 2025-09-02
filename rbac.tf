resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_virtual_desktop_scaling_plan.this.id
  role_definition_name = each.value.role_definition_id_or_name
  principal_id         = each.value.principal_id
  description          = try(each.value.description, null)
  condition            = try(each.value.condition, null)
  condition_version    = try(each.value.condition_version, null)
}

# AVD Service Principal
data "azuread_service_principal" "avd" {
  client_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
}

# Only subscriptions from enabled host pool associations
locals {
  subscription_scopes = toset([
    for hp in values(var.host_pool_associations) :
    "/subscriptions/${split("/", hp.host_pool_id)[2]}" if hp.enabled
  ])
}

# Get the GUID of the built-in role (once, if there are enabled scopes)
data "azurerm_role_definition" "power_on_off" {
  count = length(local.subscription_scopes) > 0 ? 1 : 0
  name  = "Desktop Virtualization Power On Off Contributor"
  scope = sort(tolist(local.subscription_scopes))[0]
}

# List existing role assignments per subscription
data "azapi_resource_list" "role_assignments_at_sub" {
  for_each  = local.subscription_scopes
  parent_id = each.value
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
}

# GUID of the role definition (empty if no enabled scopes)
locals {
  role_guid = length(data.azurerm_role_definition.power_on_off) > 0 ? data.azurerm_role_definition.power_on_off[0].role_definition_id : ""
}

# Map: scope -> true/false whether a matching assignment already exists
locals {
  existing_assignment = {
    for scope, d in data.azapi_resource_list.role_assignments_at_sub :
    scope => length([
      for ra in try(d.output.value, []) :
      ra if lower(try(ra.properties.principalId, "")) == lower(data.azuread_service_principal.avd.object_id) && endswith(
        lower(try(ra.properties.roleDefinitionId, "")),
        "/roledefinitions/${lower(local.role_guid)}"
      )
    ]) > 0
  }
}

# Only scopes that need an assignment
locals {
  scopes_to_assign = toset([
    for scope in local.subscription_scopes :
    scope if try(local.existing_assignment[scope], false) == false
  ])
}

# Create RBAC only where it does not yet exist
resource "azurerm_role_assignment" "avd_power_on_off_sub" {
  for_each = local.scopes_to_assign

  scope                = each.value
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = data.azuread_service_principal.avd.object_id
}
