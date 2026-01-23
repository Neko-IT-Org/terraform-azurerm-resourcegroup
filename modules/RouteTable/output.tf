###############################################################
# OUTPUT: route_table_id
# Description: Route Table resource ID
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<rt>
# Usage: Associate route table to subnets
###############################################################
output "route_table_id" {
  description = "The unique resource IDs of all route tables created by this module. Useful for referencing the route table in other modules or outputs."
  value       = azurerm_route_table.this.id
}

###############################################################
# OUTPUT: route_table_name
# Description: Route Table name
# Usage: Display, logging, or referencing in other resources
###############################################################
output "route_table_name" {
  description = "The names of all route tables created by this module. Useful for display, logging, or referencing in other resources."
  value       = azurerm_route_table.this.name
}

###############################################################
# OUTPUT: route_table_route
# Description: Route definitions applied to the route table
# Usage: Auditing, validation, documentation
###############################################################
output "route_table_route" {
  description = "The route definitions applied to each route table. Useful for auditing and validation."
  value       = azurerm_route_table.this.route
}

###############################################################
# OUTPUT: location
# Description: Route Table's Azure region
# Usage: Ensure location consistency across resources
###############################################################
output "location" {
  description = "The Azure region of the route table"
  value       = azurerm_route_table.this.location
}

###############################################################
# OUTPUT: resource_group_name
# Description: Route Table's resource group name
# Usage: Reference for other resources
###############################################################
output "resource_group_name" {
  description = "The resource group name of the route table"
  value       = azurerm_route_table.this.resource_group_name
}
