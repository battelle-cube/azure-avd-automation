resource "azurerm_role_definition" "start_vm_on_connect" {
  name = "${var.deployment_name}-start-vm-on-connect"
  scope = azurerm_resource_group.rg.id

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.rg.id
  ]
}

resource "azurerm_role_assignment" "start_vm_on_connect" {
  scope                = azurerm_resource_group.rg.id
  role_definition_id = azurerm_role_definition.start_vm_on_connect.role_definition_resource_id
  principal_id         = var.wvd_object_id
}