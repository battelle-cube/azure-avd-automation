# Create AVD Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.deployment_name
  location = var.deploy_location
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = var.deployment_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.deploy_location
  friendly_name       = "${var.deployment_name}"
  description         = "${var.deployment_name} Workspace"
}

resource "time_rotating" "avd_token" {
  rotation_days = 30
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  count = var.fix_inconsistent_final_plan_error ? 0 : var.rdsh_count

  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.deploy_location
  name                     = var.deployment_name
  friendly_name            = var.deployment_name
  validate_environment     = true
  custom_rdp_properties    = var.custom_rdp_property
  description              = "${var.deployment_name} HostPool"
  type                     = split(" ",var.host_pool_type)[0]
  start_vm_on_connect      = var.start_vm_on_connect
  maximum_sessions_allowed = var.max_session_limit
  load_balancer_type       = split(" ",var.host_pool_type)[1]

  registration_info {
    expiration_date = time_rotating.avd_token.rotation_rfc3339
  }
}

# Create AVD DAG
resource "azurerm_virtual_desktop_application_group" "dag" {
  count = var.fix_inconsistent_final_plan_error ? 0 : var.rdsh_count

  resource_group_name = azurerm_resource_group.rg.name
  host_pool_id        = azurerm_virtual_desktop_host_pool.hostpool[0].id
  location            = var.deploy_location
  type                = "Desktop"
  name                = "${var.deployment_name}-dag"
  friendly_name       = "Desktop AppGroup"
  description         = "AVD application group"
  depends_on          = [azurerm_virtual_desktop_host_pool.hostpool[0], azurerm_virtual_desktop_workspace.workspace]
}

# Associate Workspace and DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "ws-dag" {
  count = var.fix_inconsistent_final_plan_error ? 0 : var.rdsh_count

  application_group_id = azurerm_virtual_desktop_application_group.dag[0].id
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
}
