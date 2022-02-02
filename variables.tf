########################################
# Required Variables
########################################
variable "dc_admins_group_object_id" {
  type        = string
  description = "Name of built in domain admin group"
}
variable "deploy_location" {
  type        = string
  description = "The Azure Region in which all resources in this example should be created"
}
variable "deployment_name" {
  type        = string
  description = "Prefix of the name of the AVD machine(s)"
}
variable "domain_name" {
  type        = string
  description = "Name of the domain to join"
}
variable "env_name" {
  type = string
  description = "Stop gap - will be replaced with abreviated deployment name variable"
}
variable "local_admin_password" {
  type = string
  description = "Local administrator password for the AVD session hosts"
  sensitive   = true
}
variable "local_admin_username" {
  type        = string
  description = "The Local Administrator Username for the Session Hosts"
}
variable "ou_path" {
  type = string
  description = "The distinguished name for the target Organization Unit in Active Directory Domain Services."
}
variable "subnet_id" {
  type        = string
  description = "Subnet ID for session host connectivity"
}
variable "wvd_object_id" {
  type = string
  description = "the object id of the Azure Virtual Desktop enterprise application for the tenant"
}

########################################
# Optional Variables
########################################
variable "avd_users" {
  description = "Users that will be give access to this AVD workspace"
  default     = []
}
variable "custom_rdp_property" {
  type = string
  default = "audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectsmartcards:i:1"
  description = "Description: Input RDP properties to add or remove RDP functionality on the AVD host pool. Settings reference: https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context"
}
variable "fix_inconsistent_final_plan_error" {
  type = bool
  default = false
  description = "Experimental: Attempt to fix the 'Provider produced inconsistent final plan' error by removing all azurerm_virtual_machine_extension resources"
}
variable "host_pool_type" {
  type = string
  default = "Pooled DepthFirst"
  description = "These options specify the host pool type and depending on the type, provides the load balancing options and assignment types.  Allowed values are Pooled DepthFirst, Pooled BreadthFirst, Personal Automatic, Personal Direct"
}
variable "image_offer" {
  type = string
  default = "windows-ent-cpc"
  description = "Offer for the virtual machine image"
}
variable "image_publisher" {
  type = string
  default = "MicrosoftWindowsDesktop"
  description = "Publisher for the virtual machine image"
}
variable "image_sku" {
  type = string
  default = "win10-21h2-ent-cpc-m365-g2"
  description = "SKU for the virtual machine image"
}
variable "image_version" {
  type = string
  default = "latest"
  description = "Version for the virtual machine image"
}
variable "max_session_limit" {
  type = number
  default = 1
  description = "The maximum number of sessions per AVD session host."
}
variable "rdsh_count" {
  type = number
  description = "Number of AVD machines to deploy"
  default     = 2
}
variable "start_vm_on_connect" {
  type = bool
  default = true
  description = "Determines whether the Start VM On Connect feature is enabled. https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect"
}
variable "vm_size" {
  type = string
  description = "Size of the machine to deploy"
  default     = "Standard_D4s_v4"
}

