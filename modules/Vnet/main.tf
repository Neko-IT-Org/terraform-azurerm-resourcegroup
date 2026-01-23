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
