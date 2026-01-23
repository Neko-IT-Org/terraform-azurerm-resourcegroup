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

###############################################################
# OUTPUT: peering_ids
# Description: Map of peering names to peering IDs
# Format: { "peering-name" = "/subscriptions/.../virtualNetworkPeerings/peering-name", ... }
# Usage: Reference peerings in other modules or for documentation
###############################################################
output "peering_ids" {
  description = "Map of peering names to their resource IDs"
  value       = { for k, p in azurerm_virtual_network_peering.this : k => p.id }
}

###############################################################
# OUTPUT: peering_names
# Description: Map of peering names
# Format: { "peering-name" = "peering-name", ... }
# Usage: Reference peerings by name
###############################################################
output "peering_names" {
  description = "Map of peering names"
  value       = { for k, p in azurerm_virtual_network_peering.this : k => p.name }
}
