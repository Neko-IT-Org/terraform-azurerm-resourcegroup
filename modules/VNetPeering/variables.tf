###############################################################
# VARIABLE: peerings
# Type: list(object) (required)
# Description: List of VNet peering configurations to create
# Structure:
#   - name (required): Peering name (unique identifier)
#   - source_virtual_network_name (required): Source VNet name
#   - source_resource_group_name (required): Source VNet's RG
#   - source_virtual_network_id (required if reverse): Source VNet full ID
#   - remote_virtual_network_id (required): Remote VNet full ID
#   - remote_virtual_network_name (required if reverse): Remote VNet name
#   - remote_resource_group_name (required if reverse): Remote VNet's RG
#   - allow_forwarded_traffic (optional): Allow NVA forwarded traffic
#   - allow_gateway_transit (optional): Allow gateway transit
#   - allow_virtual_network_access (optional): Allow VNet communication
#   - use_remote_gateways (optional): Use remote VNet's gateway
#   - create_reverse_peering (optional): Auto-create reverse peering
#   - reverse_* (optional): Settings for reverse peering
# Validations:
#   - Gateway transit conflict check
#   - Reverse peering requirements check
###############################################################
variable "peerings" {
  description = "List of VNet peering configurations"
  type = list(object({
    ###############################################################
    # PEERING IDENTIFICATION
    ###############################################################
    # Peering name (required)
    # Example: "hub-to-spoke-app-weu-01"
    name = string

    ###############################################################
    # SOURCE VNET CONFIGURATION
    ###############################################################
    # Source VNet name (required)
    # This is the VNet from which the peering originates
    source_virtual_network_name = string

    # Source VNet's resource group (required)
    source_resource_group_name = string

    # Source VNet's full resource ID (required for reverse peering)
    # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>
    source_virtual_network_id = optional(string)

    ###############################################################
    # REMOTE (DESTINATION) VNET CONFIGURATION
    ###############################################################
    # Remote VNet's full resource ID (required)
    # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>
    remote_virtual_network_id = string

    # Remote VNet name (required for reverse peering)
    remote_virtual_network_name = optional(string)

    # Remote VNet's resource group (required for reverse peering)
    remote_resource_group_name = optional(string)

    ###############################################################
    # PEERING SETTINGS (FORWARD DIRECTION)
    ###############################################################
    # Allow forwarded traffic from NVA (default: false)
    # Set to true in spokes when hub has firewall/router
    allow_forwarded_traffic = optional(bool, false)

    # Allow gateway transit (default: false)
    # Set to true in hub if it has VPN/ExpressRoute gateway
    allow_gateway_transit = optional(bool, false)

    # Allow VNet-to-VNet communication (default: true)
    # Rarely set to false (isolation scenario)
    allow_virtual_network_access = optional(bool, true)

    # Use remote VNet's gateway (default: false)
    # Set to true in spokes to use hub's gateway
    use_remote_gateways = optional(bool, false)

    ###############################################################
    # REVERSE PEERING CONFIGURATION
    ###############################################################
    # Create reverse peering automatically (default: false)
    # Set to true to create both directions in one module call
    create_reverse_peering = optional(bool, false)

    # Custom name for reverse peering (optional)
    # Default: "reverse-{name}"
    reverse_peering_name = optional(string)

    # Reverse peering settings
    # These are typically the inverse of forward settings
    reverse_allow_forwarded_traffic      = optional(bool, false)
    reverse_allow_gateway_transit        = optional(bool, false)
    reverse_allow_virtual_network_access = optional(bool, true)
    reverse_use_remote_gateways          = optional(bool, false)
  }))

  ###############################################################
  # VALIDATION: Gateway transit conflict
  # Description: Cannot use remote gateways AND allow gateway transit
  # Logic: If use_remote_gateways is true, allow_gateway_transit must be false
  # Reason: A VNet cannot simultaneously be a gateway provider AND consumer
  ###############################################################
  validation {
    condition = alltrue([
      for p in var.peerings :
      !(p.allow_gateway_transit == true && p.use_remote_gateways == true)
    ])
    error_message = "allow_gateway_transit and use_remote_gateways cannot both be true in the same peering. A VNet cannot be both a gateway provider and consumer."
  }

  ###############################################################
  # VALIDATION: Reverse peering requirements
  # Description: If create_reverse_peering is true, remote VNet details are required
  # Logic: Checks that remote_virtual_network_name, remote_resource_group_name,
  #        and source_virtual_network_id are provided when reverse is enabled
  ###############################################################
  validation {
    condition = alltrue([
      for p in var.peerings :
      p.create_reverse_peering == false || p.create_reverse_peering == null || (
        p.remote_virtual_network_name != null &&
        p.remote_resource_group_name != null &&
        p.source_virtual_network_id != null
      )
    ])
    error_message = "When create_reverse_peering is true, remote_virtual_network_name, remote_resource_group_name, and source_virtual_network_id must be provided."
  }

  ###############################################################
  # VALIDATION: Reverse gateway transit conflict
  # Description: Same gateway conflict check for reverse peering
  ###############################################################
  validation {
    condition = alltrue([
      for p in var.peerings :
      !(p.reverse_allow_gateway_transit == true && p.reverse_use_remote_gateways == true)
    ])
    error_message = "reverse_allow_gateway_transit and reverse_use_remote_gateways cannot both be true."
  }
}

###############################################################
# VARIABLE: default_allow_forwarded_traffic
# Type: bool (optional)
# Default: false
# Description: Default value for allow_forwarded_traffic if not specified per peering
# Use Case: Set to true if most peerings are to a hub with NVA
###############################################################
variable "default_allow_forwarded_traffic" {
  description = "Default value for allow_forwarded_traffic across all peerings"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: default_allow_gateway_transit
# Type: bool (optional)
# Default: false
# Description: Default value for allow_gateway_transit if not specified per peering
# Use Case: Set to true if creating peerings FROM a hub with gateway
###############################################################
variable "default_allow_gateway_transit" {
  description = "Default value for allow_gateway_transit across all peerings"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: default_use_remote_gateways
# Type: bool (optional)
# Default: false
# Description: Default value for use_remote_gateways if not specified per peering
# Use Case: Set to true if creating peerings FROM spokes TO hub with gateway
###############################################################
variable "default_use_remote_gateways" {
  description = "Default value for use_remote_gateways across all peerings"
  type        = bool
  default     = false
}
