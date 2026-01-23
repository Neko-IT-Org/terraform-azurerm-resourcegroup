###############################################################
# RESOURCE: time_static
# Description: Captures timestamp for tracking peering creation
###############################################################
resource "time_static" "time" {}

###############################################################
# LOCAL: peering_map
# Description: Transforms the peerings list into a map for for_each
# Key format: "{source_vnet_name}-to-{destination_vnet_name}"
# Usage: Enables iteration over peering configurations
###############################################################
locals {
  # Create a map with unique keys for each peering
  peering_map = {
    for p in var.peerings :
    "${p.name}" => p
  }

  # Timestamp for tracking (not a tag, peerings don't support tags)
  created_on = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
}

###############################################################
# RESOURCE: azurerm_virtual_network_peering
# Description: Creates VNet peerings between virtual networks
# for_each: Iterates over var.peerings list
# Use Cases:
#   - Hub-and-Spoke: Connect spoke VNets to hub
#   - Spoke-to-Spoke: Connect spokes via hub (requires NVA)
#   - Cross-region: Peer VNets in different regions
#   - Cross-subscription: Peer VNets in different subscriptions
# Notes:
#   - Peering is NOT transitive (A->B and B->C doesn't mean A->C)
#   - Peering must be created in BOTH directions for bidirectional traffic
#   - Gateway transit requires a gateway in the hub VNet
###############################################################
resource "azurerm_virtual_network_peering" "this" {
  for_each = local.peering_map

  ###############################################################
  # PEERING NAME
  # Description: Unique name for the peering resource
  # Best Practice: Use descriptive names like "hub-to-spoke-app"
  ###############################################################
  name = each.value.name

  ###############################################################
  # SOURCE VNET CONFIGURATION
  # Description: The VNet from which the peering originates
  # resource_group_name: RG containing the source VNet
  # virtual_network_name: Name of the source VNet
  ###############################################################
  resource_group_name  = each.value.source_resource_group_name
  virtual_network_name = each.value.source_virtual_network_name

  ###############################################################
  # REMOTE VNET
  # Description: Full resource ID of the destination VNet
  # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>
  # Cross-subscription: Include the target subscription ID
  ###############################################################
  remote_virtual_network_id = each.value.remote_virtual_network_id

  ###############################################################
  # ALLOW FORWARDED TRAFFIC
  # Description: Allow traffic forwarded by an NVA in the remote VNet
  # Default: false
  # Use Cases:
  #   - Spoke VNets: Set to true when hub has NVA (firewall, router)
  #   - Hub VNet: Typically false unless traffic comes from another hub
  # Example: Spoke receives traffic from on-premises via hub firewall
  ###############################################################
  allow_forwarded_traffic = each.value.allow_forwarded_traffic

  ###############################################################
  # ALLOW GATEWAY TRANSIT
  # Description: Allow the remote VNet to use this VNet's gateway
  # Default: false
  # Use Cases:
  #   - Hub VNet: Set to true if hub has VPN/ExpressRoute gateway
  #   - Spoke VNets: Always false (spokes don't have gateways)
  # Requirement: This VNet must have a gateway deployed
  # Conflict: Cannot be true if use_remote_gateways is also true
  ###############################################################
  allow_gateway_transit = each.value.allow_gateway_transit

  ###############################################################
  # ALLOW VIRTUAL NETWORK ACCESS
  # Description: Allow communication between VNets
  # Default: true
  # Use Cases:
  #   - Normal peering: Keep true
  #   - Isolation scenario: Set false to peer without traffic flow (rare)
  # Note: Even if true, NSGs still control actual traffic
  ###############################################################
  allow_virtual_network_access = each.value.allow_virtual_network_access

  ###############################################################
  # USE REMOTE GATEWAYS
  # Description: Use the remote VNet's gateway for transit
  # Default: false
  # Use Cases:
  #   - Spoke VNets: Set to true to use hub's VPN/ExpressRoute gateway
  #   - Hub VNet: Always false
  # Requirements:
  #   - Remote VNet must have allow_gateway_transit = true
  #   - Remote VNet must have a gateway deployed
  # Conflict: Cannot be true if allow_gateway_transit is also true
  ###############################################################
  use_remote_gateways = each.value.use_remote_gateways

  ###############################################################
  # LIFECYCLE: Triggers
  # Description: Controls when the peering should be recreated
  # triggers: Forces recreation if specific attributes change
  # Note: Useful for cross-subscription scenarios where remote VNet
  #       might be recreated with same name but different ID
  ###############################################################
  lifecycle {
    # Prevent accidental destruction during plan/apply
    # Uncomment if peering is critical
    # prevent_destroy = true
  }
}

###############################################################
# RESOURCE: azurerm_virtual_network_peering (reverse)
# Description: Creates the reverse peering for bidirectional connectivity
# Condition: Created only if create_reverse_peering is true
# for_each: Same map as forward peering, filtered by create_reverse flag
# Use Case: Automatically create both sides of the peering
# Note: Requires permissions on both VNets/resource groups
###############################################################
resource "azurerm_virtual_network_peering" "reverse" {
  for_each = {
    for k, v in local.peering_map : k => v
    if v.create_reverse_peering == true
  }

  # Reverse peering name (prefixed with "reverse-" or custom)
  name = coalesce(each.value.reverse_peering_name, "reverse-${each.value.name}")

  # Reverse: Remote VNet becomes source
  # Extract RG name and VNet name from remote_virtual_network_id
  resource_group_name  = each.value.remote_resource_group_name
  virtual_network_name = each.value.remote_virtual_network_name

  # Reverse: Source VNet becomes remote
  remote_virtual_network_id = each.value.source_virtual_network_id

  # Reverse the gateway settings appropriately
  # If source allows gateway transit, remote should use remote gateways
  allow_forwarded_traffic = each.value.reverse_allow_forwarded_traffic

  # Reverse gateway transit logic
  # If hub (source) allows gateway transit, spoke (remote) uses remote gateways
  allow_gateway_transit = each.value.reverse_allow_gateway_transit

  # Allow VNet access (typically same as forward)
  allow_virtual_network_access = each.value.reverse_allow_virtual_network_access

  # Use remote gateways (reverse of source's allow_gateway_transit)
  use_remote_gateways = each.value.reverse_use_remote_gateways

  # Ensure forward peering is created first
  depends_on = [azurerm_virtual_network_peering.this]
}
