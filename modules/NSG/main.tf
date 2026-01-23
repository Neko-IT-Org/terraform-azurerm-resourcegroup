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
# Note: Supports both traditional address prefixes and Application Security Groups (ASG)
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
  #   - source/destination application security groups (optional)
  # Note: lookup() returns null if attribute not present (handles optionals)
  # ASG Support: Can use ASG IDs instead of address prefixes for more granular control
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
      # Cannot be used with source_application_security_group_ids
      source_address_prefix = lookup(security_rule.value, "source_address_prefix", null)

      # Destination address prefix (single, e.g., "VirtualNetwork")
      # Cannot be used with destination_application_security_group_ids
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", null)

      # Source port ranges (list, e.g., ["80", "443"])
      source_port_ranges = lookup(security_rule.value, "source_port_ranges", null)

      # Destination port ranges (list, e.g., ["80", "443"])
      destination_port_ranges = lookup(security_rule.value, "destination_port_ranges", null)

      # Source address prefixes (list, e.g., ["10.0.0.0/8", "172.16.0.0/12"])
      # Cannot be used with source_application_security_group_ids
      source_address_prefixes = lookup(security_rule.value, "source_address_prefixes", null)

      # Destination address prefixes (list)
      # Cannot be used with destination_application_security_group_ids
      destination_address_prefixes = lookup(security_rule.value, "destination_address_prefixes", null)

      # Source Application Security Group IDs (list)
      # Alternative to source_address_prefix(es) for more granular control
      # Example: ["/subscriptions/.../applicationSecurityGroups/asg-web"]
      source_application_security_group_ids = lookup(security_rule.value, "source_application_security_group_ids", null)

      # Destination Application Security Group IDs (list)
      # Alternative to destination_address_prefix(es) for more granular control
      # Example: ["/subscriptions/.../applicationSecurityGroups/asg-db"]
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null)

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

###############################################################
# RESOURCE: azurerm_monitor_diagnostic_setting
# Description: Creates diagnostic settings for the NSG
# Condition: Created only if enable_telemetry is true
# Available log categories for NSG:
#   - NetworkSecurityGroupEvent: NSG rule execution events
#   - NetworkSecurityGroupRuleCounter: Rule hit counters
###############################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_telemetry && var.telemetry_settings != null ? 1 : 0

  name               = "diag-${var.name}"
  target_resource_id = azurerm_network_security_group.this.id

  log_analytics_workspace_id     = var.telemetry_settings.log_analytics_workspace_id
  storage_account_id             = var.telemetry_settings.storage_account_id
  eventhub_authorization_rule_id = var.telemetry_settings.event_hub_authorization_rule_id
  eventhub_name                  = var.telemetry_settings.event_hub_name

  dynamic "enabled_log" {
    for_each = var.telemetry_settings.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.telemetry_settings.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}
