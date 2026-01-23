###############################################################
# RESOURCE: time_static
# Description: Captures timestamp for CreatedOn tag
###############################################################
resource "time_static" "time" {}

###############################################################
# RESOURCE: azurerm_network_security_group
# Description: Creates an Azure Network Security Group with security rules
# Inputs:
#   - var.name: NSG name
#   - var.location: Azure region
#   - var.resource_group_name: Parent RG
#   - var.security_rules: List of security rules (validated)
#   - var.tags: Custom tags
# Dynamic block:
#   - security_rule: Iterates over var.security_rules list
# Validations:
#   - Priority between 100-4096 (in variables.tf)
#   - Direction must be Inbound or Outbound (in variables.tf)
###############################################################
resource "azurerm_network_security_group" "this" {
  # NSG name
  name = var.name

  # Azure region
  location = var.location

  # Parent resource group
  resource_group_name = var.resource_group_name

  ###############################################################
  # DYNAMIC BLOCK: security_rule
  # Description: Defines one or more security rules for the NSG
  # for_each: Iterates over var.security_rules list
  # Content:
  #   - name, priority, direction, access, protocol (required)
  #   - source/destination port ranges and address prefixes (optional)
  # Note: lookup() returns null if attribute not present (handles optionals)
  ###############################################################
  dynamic "security_rule" {
    for_each = var.security_rules
    content {
      # Rule name
      name = security_rule.value.name

      # Priority (100-4096, validated)
      priority = security_rule.value.priority

      # Direction (Inbound/Outbound, validated)
      direction = security_rule.value.direction

      # Access (Allow/Deny)
      access = security_rule.value.access

      # Protocol (Tcp, Udp, Icmp, *)
      protocol = security_rule.value.protocol

      # Source port range (single, e.g., "80" or "*")
      source_port_range = lookup(security_rule.value, "source_port_range", null)

      # Destination port range (single, e.g., "443" or "*")
      destination_port_range = lookup(security_rule.value, "destination_port_range", null)

      # Source address prefix (single, e.g., "10.0.0.0/8" or "Internet")
      source_address_prefix = lookup(security_rule.value, "source_address_prefix", null)

      # Destination address prefix (single, e.g., "VirtualNetwork")
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", null)

      # Source port ranges (list, e.g., ["80", "443"])
      source_port_ranges = lookup(security_rule.value, "source_port_ranges", null)

      # Destination port ranges (list, e.g., ["80", "443"])
      destination_port_ranges = lookup(security_rule.value, "destination_port_ranges", null)

      # Source address prefixes (list, e.g., ["10.0.0.0/8", "172.16.0.0/12"])
      source_address_prefixes = lookup(security_rule.value, "source_address_prefixes", null)

      # Destination address prefixes (list)
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)

      # Rule description (for documentation/audit)
      description = lookup(security_rule.value, "description", null)
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
