###############################################################
# OUTPUT: name
# Description: Map of subnet names
# Format: { "subnet1" = "subnet1", "subnet2" = "subnet2", ... }
# Usage: Reference subnet names in other modules
###############################################################
output "name" {
  value = { for k, s in azurerm_subnet.this : k => s.name }
}

###############################################################
# OUTPUT: id
# Description: Map of subnet IDs
# Format: { "subnet1" = "/subscriptions/.../subnets/subnet1", ... }
# Usage: Associate NSG, Route Tables, or deploy resources
###############################################################
output "id" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}

###############################################################
# OUTPUT: address_prefixes
# Description: Map of subnet address prefixes
# Format: { "subnet1" = ["10.0.1.0/24"], ... }
# Usage: Validation, documentation, IPAM tracking
###############################################################
output "address_prefixes" {
  value = { for k, s in azurerm_subnet.this : k => s.address_prefixes }
}

###############################################################
# OUTPUT: virtual_network_name
# Description: Parent VNet name
# Usage: Reference in other resources, documentation
###############################################################
output "virtual_network_name" {
  value = var.virtual_network_name
}
