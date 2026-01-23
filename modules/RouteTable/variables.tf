###############################################################
# VARIABLE: name
# Type: string (required)
# Description: Route Table name
# Example: "rt-spoke-to-fw-weu-01"
###############################################################
variable "name" {
  description = "The name of the resource group"
  type        = string
}

###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Azure region where the route table will be deployed
# Example: "westeurope"
###############################################################
variable "location" {
  description = "The location of the resource group"
  type        = string
}

###############################################################
# VARIABLE: resource_group_name
# Type: string (required)
# Description: Resource group name where the route table will be created
###############################################################
variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created"
  type        = string
}

###############################################################
# VARIABLE: bgp_route_propagation_enabled
# Type: bool (optional)
# Default: true
# Description: Whether BGP route propagation is enabled
# Use Case:
#   - true: For VPN/ExpressRoute scenarios
#   - false: For spoke VNets in Hub-and-Spoke (avoid routing loops)
###############################################################
variable "bgp_route_propagation_enabled" {
  description = "Whether BGP route propagation is enabled for the route table"
  type        = bool
  default     = true
}

###############################################################
# VARIABLE: route
# Type: list(object) (required)
# Description: List of route objects to add to the route table
# Structure:
#   - name (required): Route name
#   - address_prefix (required): Destination CIDR (e.g., "0.0.0.0/0")
#   - next_hop_type (required): Type of next hop (validated)
#   - next_hop_in_ip_address (optional, required for VirtualAppliance): Next hop IP
# Validations:
#   - next_hop_type must be one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None
#   - next_hop_in_ip_address required when next_hop_type = VirtualAppliance
# Next hop types:
#   - VirtualNetworkGateway: VPN/ExpressRoute Gateway
#   - VnetLocal: Route within VNet
#   - Internet: Route to Internet
#   - VirtualAppliance: Route to NVA (firewall)
#   - None: Blackhole route (drop traffic)
###############################################################
variable "route" {
  description = "A list of routes to be added to the route table"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))

  ###############################################################
  # VALIDATION: next_hop_type
  # Description: Ensures next_hop_type is a valid Azure value
  # Valid values: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, None
  ###############################################################
  validation {
    condition = alltrue([
      for r in var.route : contains(
        ["VirtualNetworkGateway", "VnetLocal", "Internet", "VirtualAppliance", "None"],
        r.next_hop_type
      )
    ])
    error_message = "next_hop_type must be one of: VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance, or None."
  }

  ###############################################################
  # VALIDATION: next_hop_in_ip_address for VirtualAppliance
  # Description: Ensures next_hop_in_ip_address is provided when next_hop_type = VirtualAppliance
  # Logic: If next_hop_type == "VirtualAppliance" then next_hop_in_ip_address must not be null
  ###############################################################
  validation {
    condition = alltrue([
      for r in var.route :
      r.next_hop_type != "VirtualAppliance" || r.next_hop_in_ip_address != null
    ])
    error_message = "next_hop_in_ip_address is required when next_hop_type is VirtualAppliance."
  }
}

###############################################################
# VARIABLE: tags
# Type: map(string) (optional)
# Default: {} (empty map)
# Description: Tags to assign to the route table
# Example: { environment = "prod", purpose = "force-traffic-through-firewall" }
###############################################################
variable "tags" {
  description = "A map of tags to assign to the resource group"
  type        = map(string)
  default     = {}
}

###############################################################
# VARIABLE: enable_telemetry
# Type: bool (optional)
# Default: false
# Description: Enable diagnostic settings for Route Table telemetry
###############################################################
variable "enable_telemetry" {
  description = "Enable diagnostic settings for telemetry"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: telemetry_settings
# Type: object (optional, nullable)
# Default: null
# Description: Diagnostic settings configuration for Route Table telemetry
# Note: Route Tables have limited diagnostic capabilities
###############################################################
variable "telemetry_settings" {
  description = "Diagnostic settings configuration for telemetry"
  type = object({
    log_analytics_workspace_id      = optional(string)
    storage_account_id              = optional(string)
    event_hub_authorization_rule_id = optional(string)
    event_hub_name                  = optional(string)
    metric_categories               = optional(list(string), ["AllMetrics"])
  })
  default  = null
  nullable = true

  validation {
    condition = var.telemetry_settings == null || (
      var.telemetry_settings.log_analytics_workspace_id != null ||
      var.telemetry_settings.storage_account_id != null ||
      var.telemetry_settings.event_hub_authorization_rule_id != null
    )
    error_message = "If telemetry_settings is provided, at least one destination must be specified."
  }
}
