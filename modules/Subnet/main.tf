resource "azurerm_subnet" "this" {
  for_each                          = { for s in var.subnets : s.name => s }
  name                              = each.value.name
  resource_group_name               = var.resource_group_name
  virtual_network_name              = var.virtual_network_name
  address_prefixes                  = each.value.address_prefixes
  service_endpoints                 = lookup(each.value, "service_endpoints", null)
  default_outbound_access_enabled   = lookup(each.value, "default_outbound_access_enabled", null)
  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies", null)

  dynamic "ip_address_pool" {
    for_each = lookup(each.value, "ip_address_pool", null) != null ? [each.value.ip_address_pool] : []
    content {
      id                     = ip_address_pool.value.id
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
    }
  }
  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for s in var.subnets : s.name => s
    if contains(keys(s), "nsg_id") && s.nsg_id != null
  }
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value.nsg_id
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for s in var.subnets : s.name => s
    if contains(keys(s), "route_table_id") && s.route_table_id != null
  }
  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = each.value.route_table_id
}
