###############################################################
# RESOURCE: time_static
# Description: Captures timestamp for CreatedOn tag
###############################################################
resource "time_static" "time" {}

###############################################################
# RESOURCE: azurerm_route_table
# Description: Creates an Azure Route Table with custom routes
# Inputs:
#   - var.name: Route Table name
#   - var.location: Azure region
#   - var.resource_group_name: Parent RG
#   - var.bgp_route_propagation_enabled: Enable/disable BGP propagation
#   - var.route: List of routes (validated)
#   - var.tags: Custom tags
# Dynamic block:
#   - route: Iterates over var.route list
# Validations:
#   - next_hop_type must be valid Azure type (in variables.tf)
#   - next_hop_in_ip_address required for VirtualAppliance (in variables.tf)
# Use Case: Force traffic through firewall (Hub-and-Spoke)
###############################################################
resource "azurerm_route_table" "this" {
  # Route Table name
  name = var.name

  # Azure region
  location = var.location

  # Parent resource group
  resource_group_name = var.resource_group_name

  # BGP route propagation (default: true)
  # Set to false in spokes to avoid routing loops
  bgp_route_propagation_enabled = var.bgp_route_propagation_enabled

  ###############################################################
  # DYNAMIC BLOCK: route
  # Description: Defines one or more routes for the route table
  # for_each: Iterates over var.route list
  # Content:
  #   - name: Route name
  #   - address_prefix: Destination CIDR (e.g., "0.0.0.0/0")
  #   - next_hop_type: Type of next hop (validated)
  #   - next_hop_in_ip_address: IP of next hop (required for VirtualAppliance)
  # Note: lookup() returns null if next_hop_in_ip_address not present
  ###############################################################
  dynamic "route" {
    for_each = var.route
    content {
      # Route name
      name = route.value.name

      # Destination CIDR block (e.g., "0.0.0.0/0", "10.0.0.0/8")
      address_prefix = route.value.address_prefix

      # Next hop type (VirtualAppliance, Internet, VnetLocal, etc.)
      next_hop_type = route.value.next_hop_type

      # Next hop IP address (required if next_hop_type = VirtualAppliance)
      # Example: "10.0.2.4" (Palo Alto Trust interface IP)
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }

  # Tags: Merge user tags + auto CreatedOn
  tags = merge(
    var.tags,
    {
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}
