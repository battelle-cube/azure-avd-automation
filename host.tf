locals {
  registration_token = var.fix_inconsistent_final_plan_error ? null : azurerm_virtual_desktop_host_pool.hostpool[0].registration_info[0].token
  user_principal_name = "avd-${var.deployment_name}-temp-admin-user@${var.domain_name}"
  # user_principal_password = "Pa55w0Rd!!1"
}

resource "random_string" "user_principal_password" {
  length           = 16
  special          = true
  min_special      = 2
  override_special = "*!@#?"
}

# create a temporary user that will be used to join vms to the domain
resource "azuread_user" "admin" {
  user_principal_name = local.user_principal_name
  display_name        = "AVD ${var.deployment_name} DC Administrator"
  password            = random_string.user_principal_password.result
}

resource "azuread_group_member" "admin" {
  group_object_id  = var.dc_admins_group_object_id
  member_object_id = azuread_user.admin.object_id
}

resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.deployment_name}-${count.index + 1}-nic"
  resource_group_name = var.deployment_name
  location            = var.deploy_location

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "dynamic"
  }

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = var.rdsh_count
  name                  = "${var.env_name}-${count.index + 1}"
  resource_group_name   = var.deployment_name
  location              = var.deploy_location
  size                  = var.vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.local_admin_username
  admin_password        = var.local_admin_password

  os_disk {
    name                 = "${lower(var.deployment_name)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_network_interface.avd_vm_nic
  ]
}

resource "azurerm_virtual_machine_extension" "domain_join" {
  count = var.fix_inconsistent_final_plan_error ? 0 : var.rdsh_count
  name                       = "${var.deployment_name}-${count.index + 1}-domainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.ou_path}",
      "User": "${azuread_user.admin.user_principal_name}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${random_string.user_principal_password.result}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count = var.fix_inconsistent_final_plan_error ? 0 : var.rdsh_count

  name                       = "${var.deployment_name}${count.index + 1}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.usgovcloudapi.net/galleryartifacts/Configuration_3-10-2021.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${azurerm_virtual_desktop_host_pool.hostpool[0].name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${local.registration_token}"
    }
  }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_desktop_host_pool.hostpool
  ]
}

# resource "azurerm_virtual_machine_extension" "vmext_stig" {
#   count                      = var.rdsh_count
#   name                       = "${var.deployment_name}-${count.index + 1}-stig"
#   virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
#   publisher                  = "Microsoft.Powershell"
#   type                       = "DSC"
#   type_handler_version       = "2.77"
#   auto_upgrade_minor_version = true

#   settings = <<SETTINGS
#     {
#       "url": "https://raw.githubusercontent.com/Azure/ato-toolkit/master/stig/windows/Windows.ps1.zip",
#       "script": "Windows.ps1",
#       "funcion": "Windows"
#     }
# SETTINGS

#   protected_settings = <<PROTECTED_SETTINGS
#     {
      
#     }
# PROTECTED_SETTINGS

#   # lifecycle {
#   #   ignore_changes = [settings, protected_settings]
#   # }

# }
