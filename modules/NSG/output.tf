###############################################################
# OUTPUT: id
# Description: NSG resource ID
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<nsg>
# Usage: Associate NSG to subnets or NICs
###############################################################
output "id" {
  description = "The unique resource IDs of all NSGs created by this module. Useful for referencing the NSG in other modules or outputs."
  value       = azurerm_network_security_group.this.id
}

###############################################################
# OUTPUT: name
# Description: NSG name
# Usage: Display, logging, or referencing in other resources
###############################################################
output "name" {
  description = "The names of all NSGs created by this module. Useful for display, logging, or referencing in other resources."
  value       = azurerm_network_security_group.this.name
}

###############################################################
# OUTPUT: security_rule
# Description: Security rules applied to the NSG
# Usage: Auditing, validation, documentation
###############################################################
output "security_rule" {
  description = "The security rules applied to each NSG. Useful for auditing and validation."
  value       = azurerm_network_security_group.this.security_rule
}

###############################################################
# OUTPUT: location
# Description: NSG's Azure region
# Usage: Ensure location consistency
###############################################################
output "location" {
  description = "The Azure region of the NSG"
  value       = azurerm_network_security_group.this.location
}

###############################################################
# OUTPUT: resource_group_name
# Description: NSG's resource group name
# Usage: Reference for other resources
###############################################################
output "resource_group_name" {
  description = "The resource group name of the NSG"
  value       = azurerm_network_security_group.this.resource_group_name
}
