###############################################################
# RESOURCE: azurerm_subnet
# Description: Creates one or more Azure subnets within a VNet
# for_each: Iterates over var.subnets list, key = subnet name
# Inputs:
#   - var.resource_group_name: Parent RG
#   - var.virtual_network_name: Parent VNet
#   - var.subnets: List of subnet objects
# Dynamic blocks:
#   - ip_address_pool: Created if ip_address_pool provided
#   - delegation: Created for each delegation in list
# Note: Subnets do NOT support tags (Azure limitation)
###############################################################
resource "azurerm_subnet" "this" {
  # for_each: Create one subnet per element in var.subnets
  # Key = subnet name (must be unique)
  for_each = { for s in var.subnets : s.name => s }

  # Subnet name
  name = each.value.name

  # Parent resource group
  resource_group_name = var.resource_group_name

  # Parent virtual network
  virtual_network_name = var.virtual_network_name

  # Address prefixes (CIDR blocks)
  # Example: ["10.0.1.0/24"]
  address_prefixes = each.value.address_prefixes

  # Service endpoints (e.g., ["Microsoft.Storage", "Microsoft.Sql"])
  # lookup() returns null if not present
  service_endpoints = lookup(each.value, "service_endpoints", null)

  # Default outbound access enabled (true/false)
  # Default: false (if not specified)
  default_outbound_access_enabled = lookup(each.value, "default_outbound_access_enabled", null)

  # Private endpoint network policies ("Enabled" or "Disabled")
  # "Disabled" required for private endpoints
  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies", null)

  ###############################################################
  # DYNAMIC BLOCK: ip_address_pool
  # Condition: Created only if ip_address_pool is provided in subnet config
  # for_each: If ip_address_pool != null → list with object, else empty list
  # Usage: Azure IPAM for centralized IP management
  ###############################################################
  dynamic "ip_address_pool" {
    for_each = lookup(each.value, "ip_address_pool", null) != null ? [each.value.ip_address_pool] : []
    content {
      id                     = ip_address_pool.value.id
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
    }
  }

  ###############################################################
  # DYNAMIC BLOCK: delegation
  # Description: Delegates subnet to Azure managed services
  # for_each: Iterates over delegations list (default: empty list)
  # Use Cases:
  #   - Microsoft.Sql/managedInstances (SQL Managed Instance)
  #   - Microsoft.Web/serverFarms (App Service)
  #   - Microsoft.ContainerInstance/containerGroups (ACI)
  # Note: Delegated subnets become exclusive to that service
  ###############################################################
  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
    content {
      # Delegation name
      name = delegation.value.name

      # Service delegation configuration
      service_delegation {
        # Service name (e.g., "Microsoft.Sql/managedInstances")
        name = delegation.value.service_delegation.name

        # Actions allowed by the service
        # Example: ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

###############################################################
# RESOURCE: azurerm_subnet_network_security_group_association
# Description: Associates NSG to subnet (if nsg_id provided)
# for_each: Iterates only over subnets that have nsg_id defined
# Condition: Created only if nsg_id is present and not null
# Usage: Apply security rules to subnet traffic
###############################################################
resource "azurerm_subnet_network_security_group_association" "this" {
  # for_each: Filter subnets where nsg_id is defined and not null
  # contains(keys(s), "nsg_id") checks if nsg_id key exists
  # s.nsg_id != null ensures value is not null
  for_each = {
    for s in var.subnets : s.name => s
    if contains(keys(s), "nsg_id") && s.nsg_id != null
  }

  # Subnet to associate
  subnet_id = azurerm_subnet.this[each.key].id

  # NSG to associate
  network_security_group_id = each.value.nsg_id
}

###############################################################
# RESOURCE: azurerm_subnet_route_table_association
# Description: Associates Route Table to subnet (if route_table_id provided)
# for_each: Iterates only over subnets that have route_table_id defined
# Condition: Created only if route_table_id is present and not null
# Usage: Force traffic through firewall or custom routes
###############################################################
resource "azurerm_subnet_route_table_association" "this" {
  # for_each: Filter subnets where route_table_id is defined and not null
  for_each = {
    for s in var.subnets : s.name => s
    if contains(keys(s), "route_table_id") && s.route_table_id != null
  }

  # Subnet to associate
  subnet_id = azurerm_subnet.this[each.key].id

  # Route Table to associate
  route_table_id = each.value.route_table_id
}
