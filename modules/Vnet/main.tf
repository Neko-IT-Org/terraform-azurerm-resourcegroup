###############################################################
# RESOURCE: time_static
# Description: Captures timestamp for CreatedOn tag
###############################################################
resource "time_static" "time" {}

###############################################################
# RESOURCE: azurerm_virtual_network
# Description: Creates an Azure Virtual Network
# Inputs:
#   - var.name: VNet name
#   - var.address_space: CIDR blocks (e.g., ["10.0.0.0/16"])
#   - var.location: Azure region
#   - var.resource_group_name: Parent RG
#   - var.dns_servers: Custom DNS (optional)
#   - var.enable_ddos_protection: Enable DDoS Protection
#   - var.ddos_protection_plan_id: DDoS plan ID
#   - var.ip_address_pool: IPAM configuration
# Dynamic blocks:
#   - ddos_protection_plan: Created if enable_ddos AND plan_id provided
#   - ip_address_pool: Created if ip_address_pool provided
###############################################################
resource "azurerm_virtual_network" "this" {
  # VNet name
  name = var.name

  # Address space: If empty list, set null (rare, for VNet without CIDR)
  # Logic: If var.address_space != [] then use var.address_space, else null
  address_space = var.address_space != [] ? var.address_space : null

  # Azure region
  location = var.location

  # Parent resource group
  resource_group_name = var.resource_group_name

  # DNS servers: If empty list, set null (uses Azure default DNS)
  # Logic: If var.dns_servers != [] then use var.dns_servers, else null
  dns_servers = var.dns_servers != [] ? var.dns_servers : null

  ###############################################################
  # DYNAMIC BLOCK: ddos_protection_plan
  # Condition: Created only if enable_ddos_protection = true AND ddos_protection_plan_id != null
  # for_each: If condition true → list with 1 element (plan_id), else empty list
  # Usage: DDoS protection for critical production VNets
  ###############################################################
  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection && var.ddos_protection_plan_id != null ? [var.ddos_protection_plan_id] : []
    content {
      enable = var.enable_ddos_protection
      id     = ddos_protection_plan.value
    }
  }

  ###############################################################
  # DYNAMIC BLOCK: ip_address_pool
  # Condition: Created only if var.ip_address_pool != null
  # for_each: If ip_address_pool provided → list with object, else empty list
  # Usage: Azure IPAM for centralized IP management
  ###############################################################
  dynamic "ip_address_pool" {
    for_each = var.ip_address_pool == null ? [] : [var.ip_address_pool]
    content {
      id                     = ip_address_pool.value.id
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
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
# RESOURCE: azurerm_virtual_network_peering
# Description: Creates VNet peerings to remote VNets
# for_each: Iterates over var.peerings list
# Conditions:
#   - Created only if var.peerings is not empty
# Use Cases:
#   - Hub-and-Spoke architectures
#   - Cross-region connectivity
#   - Workload isolation with connectivity
# Note: Peering must be created in BOTH directions (this module + remote)
###############################################################
resource "azurerm_virtual_network_peering" "this" {
  # for_each: Create one peering per element in var.peerings
  # Key = peering name (must be unique)
  for_each = { for p in var.peerings : p.name => p }

  # Peering name
  name = each.value.name

  # Source VNet (this VNet)
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name

  # Remote VNet to peer with
  remote_virtual_network_id = each.value.remote_virtual_network_id

  # Allow forwarded traffic from remote VNet
  # Set to true in spokes when hub has NVA (firewall, router)
  allow_forwarded_traffic = lookup(each.value, "allow_forwarded_traffic", false)

  # Allow gateway transit (this VNet provides gateway to remote)
  # Set to true in hub if it has VPN/ExpressRoute gateway
  allow_gateway_transit = lookup(each.value, "allow_gateway_transit", false)

  # Allow virtual network access
  # Set to false to block communication (rare)
  allow_virtual_network_access = lookup(each.value, "allow_virtual_network_access", true)

  # Use remote gateways (use remote VNet's gateway)
  # Set to true in spokes to use hub's VPN/ExpressRoute gateway
  # Cannot be true if allow_gateway_transit is true
  use_remote_gateways = lookup(each.value, "use_remote_gateways", false)
}

###############################################################
# RESOURCE: azurerm_monitor_diagnostic_setting
# Description: Creates diagnostic settings for the VNet
# Condition: Created only if enable_telemetry is true
# Available log categories for VNet:
#   - VMProtectionAlerts: DDoS protection alerts
# Available metrics: AllMetrics (limited for VNet)
###############################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_telemetry && var.telemetry_settings != null ? 1 : 0

  name               = "diag-${var.name}"
  target_resource_id = azurerm_virtual_network.this.id

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
