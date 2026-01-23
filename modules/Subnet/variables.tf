###############################################################
# VARIABLE: resource_group_name
# Type: string (required)
# Description: Resource group name where subnets will be created
###############################################################
variable "resource_group_name" {
  type = string
}

###############################################################
# VARIABLE: virtual_network_name
# Type: string (required)
# Description: Virtual network name to which subnets belong
###############################################################
variable "virtual_network_name" {
  type = string
}

###############################################################
# VARIABLE: subnets
# Type: list(object) (required)
# Description: List of subnet objects to create within the VNet
# Structure:
#   - name (required): Subnet name (must be unique in VNet)
#   - address_prefixes (optional): CIDR blocks (e.g., ["10.0.1.0/24"])
#   - nsg_id (optional): NSG resource ID to associate
#   - service_endpoints (optional): Service endpoints list
#   - route_table_id (optional): Route Table resource ID to associate
#   - ip_address_pool (optional): IPAM pool configuration
#   - private_endpoint_network_policies (optional): "Enabled" or "Disabled" (string)
#   - default_outbound_access_enabled (optional): true/false (default: false)
#   - delegations (optional): List of delegation objects
# Note: Subnets do NOT support tags (Azure limitation)
###############################################################
variable "subnets" {
  type = list(object({
    # Subnet name (required)
    name = string

    # Address prefixes (optional)
    # Example: ["10.0.1.0/24"]
    address_prefixes = optional(list(string))

    # NSG ID to associate (optional)
    # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/networkSecurityGroups/<nsg>
    nsg_id = optional(string)

    # Service endpoints (optional)
    # Example: ["Microsoft.Storage", "Microsoft.KeyVault"]
    service_endpoints = optional(list(string))

    # Route Table ID to associate (optional)
    # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/routeTables/<rt>
    route_table_id = optional(string)

    # IP address pool configuration (optional)
    # Used for Azure IPAM
    ip_address_pool = optional(object({
      id                     = string
      number_of_ip_addresses = number
    }))

    # Private endpoint network policies (optional)
    # Values: "Enabled" or "Disabled" (string, not bool!)
    # "Disabled" required for private endpoints
    private_endpoint_network_policies = optional(string)

    # Default outbound access enabled (optional)
    # Default: false
    # Set to true for subnets requiring internet outbound
    default_outbound_access_enabled = optional(bool, false)

    # Delegations (optional)
    # Default: [] (empty list)
    # Used for Azure managed services (SQL MI, App Service, etc.)
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
  }))
}
