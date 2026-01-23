###############################################################
# OUTPUT: id
# Description: Full resource group ID
# Format: /subscriptions/<sub-id>/resourceGroups/<rg-name>
# Usage: Reference the RG in other modules (e.g., scope for locks)
###############################################################
output "id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.this.id
}

###############################################################
# OUTPUT: name
# Description: Created resource group name
# Usage: Pass RG name to other resources (VNet, NSG, etc.)
###############################################################
output "name" {
  description = "The Name of the resource group"
  value       = azurerm_resource_group.this.name
}

###############################################################
# OUTPUT: location
# Description: Azure region of the resource group
# Usage: Ensure location consistency across resources
###############################################################
output "location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.this.location
}

###############################################################
# OUTPUT: tags
# Description: All tags applied to the RG (including CreatedOn)
# Usage: Audit, reporting, copy tags to other resources
###############################################################
output "tags" {
  description = "The complete tags applied to the resource group"
  value       = azurerm_resource_group.this.tags
}
