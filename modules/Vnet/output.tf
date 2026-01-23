###############################################################
# OUTPUT: id
# Description: Full VNet ID
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>
# Usage: Reference the VNet in other modules
###############################################################
output "id" {
  description = "The unique resource IDs of VNets created by this module."
  value       = azurerm_virtual_network.this.id
}

###############################################################
# OUTPUT: name
# Description: Created VNet name
# Usage: Pass to Subnet, Peering modules, etc.
###############################################################
output "name" {
  description = "The names of the VNets created by this module."
  value       = azurerm_virtual_network.this.name
}

###############################################################
# OUTPUT: resource_group_name
# Description: VNet's resource group name
# Usage: Deployment consistency
###############################################################
output "resource_group_name" {
  description = "The resource group names of the VNets created by this module."
  value       = azurerm_virtual_network.this.resource_group_name
}

###############################################################
# OUTPUT: location
# Description: VNet's Azure region
###############################################################
output "location" {
  description = "The locations of the VNets created by this module."
  value       = azurerm_virtual_network.this.location
}

###############################################################
# OUTPUT: tags
# Description: All applied tags (including CreatedOn)
###############################################################
output "tags" {
  description = "The tags assigned to the VNets created by this module."
  value       = azurerm_virtual_network.this.tags
}
