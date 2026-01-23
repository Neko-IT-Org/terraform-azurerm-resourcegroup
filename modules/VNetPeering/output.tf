###############################################################
# OUTPUT: peering_ids
# Description: Map of peering names to their resource IDs
# Format: { "peering-name" = "/subscriptions/.../virtualNetworkPeerings/peering-name", ... }
# Usage: Reference peerings in other modules, monitoring, or documentation
###############################################################
output "peering_ids" {
  description = "Map of forward peering names to their Azure resource IDs"
  value       = { for k, p in azurerm_virtual_network_peering.this : k => p.id }
}

###############################################################
# OUTPUT: peering_names
# Description: Map of peering keys to their names
# Format: { "key" = "peering-name", ... }
# Usage: Reference peering names for logging or documentation
###############################################################
output "peering_names" {
  description = "Map of forward peering keys to their names"
  value       = { for k, p in azurerm_virtual_network_peering.this : k => p.name }
}

###############################################################
# OUTPUT: peering_states
# Description: Map of peering names to their provisioning states
# Format: { "peering-name" = "Connected", ... }
# Possible values: Initiated, Connected, Disconnected
# Usage: Verify peering status after deployment
###############################################################
output "peering_states" {
  description = "Map of forward peering names to their peering states"
  value       = { for k, p in azurerm_virtual_network_peering.this : k => p.peering_state }
}

###############################################################
# OUTPUT: reverse_peering_ids
# Description: Map of reverse peering names to their resource IDs
# Format: { "reverse-peering-name" = "/subscriptions/.../virtualNetworkPeerings/...", ... }
# Usage: Reference reverse peerings when create_reverse_peering is true
###############################################################
output "reverse_peering_ids" {
  description = "Map of reverse peering names to their Azure resource IDs (if created)"
  value       = { for k, p in azurerm_virtual_network_peering.reverse : k => p.id }
}

###############################################################
# OUTPUT: reverse_peering_names
# Description: Map of reverse peering keys to their names
# Format: { "key" = "reverse-peering-name", ... }
# Usage: Reference reverse peering names
###############################################################
output "reverse_peering_names" {
  description = "Map of reverse peering keys to their names (if created)"
  value       = { for k, p in azurerm_virtual_network_peering.reverse : k => p.name }
}

###############################################################
# OUTPUT: reverse_peering_states
# Description: Map of reverse peering names to their states
# Format: { "reverse-peering-name" = "Connected", ... }
# Usage: Verify reverse peering status
###############################################################
output "reverse_peering_states" {
  description = "Map of reverse peering names to their peering states (if created)"
  value       = { for k, p in azurerm_virtual_network_peering.reverse : k => p.peering_state }
}

###############################################################
# OUTPUT: all_peering_ids
# Description: Combined map of all peering IDs (forward + reverse)
# Format: { "peering-name" = "id", "reverse-peering-name" = "id", ... }
# Usage: Single output for all peerings
###############################################################
output "all_peering_ids" {
  description = "Combined map of all peering IDs (forward and reverse)"
  value = merge(
    { for k, p in azurerm_virtual_network_peering.this : k => p.id },
    { for k, p in azurerm_virtual_network_peering.reverse : "reverse-${k}" => p.id }
  )
}

###############################################################
# OUTPUT: peering_details
# Description: Detailed information about each forward peering
# Includes: name, id, state, source VNet, remote VNet, settings
# Usage: Comprehensive peering documentation and auditing
###############################################################
output "peering_details" {
  description = "Detailed information about each forward peering"
  value = {
    for k, p in azurerm_virtual_network_peering.this : k => {
      id                           = p.id
      name                         = p.name
      peering_state                = p.peering_state
      source_vnet_name             = p.virtual_network_name
      source_resource_group        = p.resource_group_name
      remote_vnet_id               = p.remote_virtual_network_id
      allow_forwarded_traffic      = p.allow_forwarded_traffic
      allow_gateway_transit        = p.allow_gateway_transit
      allow_virtual_network_access = p.allow_virtual_network_access
      use_remote_gateways          = p.use_remote_gateways
    }
  }
}

###############################################################
# OUTPUT: created_timestamp
# Description: Timestamp when the peerings were created
# Format: DD-MM-YYYY hh:mm (Brussels/Paris time)
# Usage: Audit trail for peering creation
###############################################################
output "created_timestamp" {
  description = "Timestamp when the peerings were created (for audit purposes)"
  value       = local.created_on
}
