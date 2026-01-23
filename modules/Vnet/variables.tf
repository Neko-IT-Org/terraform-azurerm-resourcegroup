###############################################################
# VARIABLE: name
# Type: string (required)
# Description: Virtual Network name
# Example: "vnet-hub-neko-weu-01"
###############################################################
variable "name" {
  description = "The name of the resource group"
  type        = string
}

###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Azure region
# Example: "westeurope"
###############################################################
variable "location" {
  description = "The location of the resource group"
  type        = string
}

###############################################################
# VARIABLE: tags
# Type: map(string) (required)
# Description: Custom tags for the VNet
###############################################################
variable "tags" {
  description = "A map of tags to assign to the resource group"
  type        = map(string)
}

###############################################################
# VARIABLE: resource_group_name
# Type: string (required)
# Description: Parent resource group name
###############################################################
variable "resource_group_name" {
  description = "A map of tags to assign to the resource group"
  type        = string
}

###############################################################
# VARIABLE: enable_ddos_protection
# Type: bool (optional)
# Default: false
# Description: Enables DDoS protection on the VNet
# Note: Requires ddos_protection_plan_id if true
###############################################################
variable "enable_ddos_protection" {
  description = "Whether to enable the DDoS protection plan on the virtual network"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: ddos_protection_plan_id
# Type: string (optional, nullable)
# Default: null
# Description: DDoS Protection Plan ID to associate
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/ddosProtectionPlans/<name>
###############################################################
variable "ddos_protection_plan_id" {
  description = "The ID of the DDoS protection plan to associate with the virtual network"
  type        = string
  default     = null
  nullable    = true
}

###############################################################
# VARIABLE: address_space
# Type: list(string) (optional, nullable)
# Default: null
# Description: VNet CIDR blocks
# Example: ["10.0.0.0/16", "172.16.0.0/16"]
# Note: If null/empty, VNet created without address space (rare)
###############################################################
variable "address_space" {
  description = "The CIDR block for the virtual network"
  type        = list(string)
  default     = null
  nullable    = true
}

###############################################################
# VARIABLE: dns_servers
# Type: list(string) (optional, nullable)
# Default: null
# Description: Custom DNS server IPs
# Example: ["10.0.0.4", "10.0.0.5"]
# Note: If null/empty, uses Azure default DNS
###############################################################
variable "dns_servers" {
  description = "IP addresses of DNS servers to be used by the virtual network"
  type        = list(string)
  default     = null
  nullable    = true
}

###############################################################
# VARIABLE: ip_address_pool
# Type: object (optional, nullable)
# Default: null
# Description: Azure IPAM pool configuration
# Structure:
#   - id: IPAM pool ID
#   - number_of_ip_addresses: Number of IPs to allocate (string!)
# Note: number_of_ip_addresses is string because Azure API requires it
###############################################################
variable "ip_address_pool" {
  description = "Optional single IPAM pool to allocate addresses from at VNET level."
  type = object({
    id                     = string
    number_of_ip_addresses = string
  })
  default  = null
  nullable = true
}

###############################################################
# VARIABLE: peerings
# Type: list(object) (optional)
# Default: []
# Description: List of VNet peerings to create
# Structure:
#   - name (required): Peering name
#   - remote_virtual_network_id (required): Remote VNet ID
#   - allow_forwarded_traffic (optional): Allow traffic forwarded by NVA (default: false)
#   - allow_gateway_transit (optional): Allow remote to use this VNet's gateway (default: false)
#   - allow_virtual_network_access (optional): Allow communication (default: true)
#   - use_remote_gateways (optional): Use remote VNet's gateway (default: false)
# Note: Peering must be created in BOTH VNets (bidirectional)
# Use Cases:
#   - Hub-and-Spoke: Hub allows gateway transit, spokes use remote gateways
#   - Spoke-to-Spoke: Via hub with allow_forwarded_traffic
###############################################################
variable "peerings" {
  description = "List of VNet peerings to create from this VNet"
  type = list(object({
    name                         = string
    remote_virtual_network_id    = string
    allow_forwarded_traffic      = optional(bool, false)
    allow_gateway_transit        = optional(bool, false)
    allow_virtual_network_access = optional(bool, true)
    use_remote_gateways          = optional(bool, false)
  }))
  default = []

  ###############################################################
  # VALIDATION: Gateway transit conflict
  # Description: Cannot use remote gateways AND provide gateway transit
  # Logic: allow_gateway_transit and use_remote_gateways cannot both be true
  ###############################################################
  validation {
    condition = alltrue([
      for p in var.peerings :
      !(p.allow_gateway_transit == true && p.use_remote_gateways == true)
    ])
    error_message = "allow_gateway_transit and use_remote_gateways cannot both be true in the same peering."
  }
}
