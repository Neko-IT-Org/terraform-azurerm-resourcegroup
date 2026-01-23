###############################################################
# VARIABLE: name
# Type: string (required)
# Description: Network Security Group name
# Example: "nsg-mgmt-hub-weu-01"
###############################################################
variable "name" {
  description = "The name of the NSG"
  type        = string
}

###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Azure region where the NSG will be deployed
# Example: "westeurope"
###############################################################
variable "location" {
  description = "The location of the NSG"
  type        = string
}

###############################################################
# VARIABLE: resource_group_name
# Type: string (required)
# Description: Resource group name where the NSG will be created
###############################################################
variable "resource_group_name" {
  description = "The name of the resource group where the NSG will be created"
  type        = string
}

###############################################################
# VARIABLE: tags
# Type: map(string) (required)
# Description: Tags to assign to the NSG for organization and management
# Example: { environment = "prod", criticality = "high" }
###############################################################
variable "tags" {
  description = "A map of tags to assign to the NSG"
  type        = map(string)
}

###############################################################
# VARIABLE: security_rules
# Type: list(object) (required)
# Description: List of security rule objects to apply to the NSG
# Structure:
#   - name (required): Rule name
#   - priority (required): Rule priority (100-4096)
#   - direction (required): "Inbound" or "Outbound"
#   - access (required): "Allow" or "Deny"
#   - protocol (required): "Tcp", "Udp", "Icmp", or "*"
#   - source_port_range (optional): Single source port (e.g., "80", "*")
#   - destination_port_range (optional): Single destination port
#   - source_address_prefix (optional): Single source address (e.g., "10.0.0.0/8")
#   - destination_address_prefix (optional): Single destination address
#   - source_port_ranges (optional): List of source ports
#   - destination_port_ranges (optional): List of destination ports
#   - source_address_prefixes (optional): List of source addresses
#   - destination_address_prefixes (optional): List of destination addresses
#   - description (optional): Rule description
# Validations:
#   - Priority must be between 100 and 4096
#   - Direction must be "Inbound" or "Outbound"
###############################################################
variable "security_rules" {
  description = "List of security rules for the NSG"
  type = list(object({
    name      = string
    priority  = number
    direction = string
    access    = string
    protocol  = string

    source_port_range            = optional(string)
    destination_port_range       = optional(string)
    source_address_prefix        = optional(string)
    destination_address_prefix   = optional(string)
    source_port_ranges           = optional(list(string))
    destination_port_ranges      = optional(list(string))
    source_address_prefixes      = optional(list(string))
    destination_address_prefixes = optional(list(string))
    description                  = optional(string)
  }))

  ###############################################################
  # VALIDATION: priority range
  # Description: Ensures all rule priorities are between 100-4096
  # Azure limits: Priorities must be unique and in valid range
  ###############################################################
  validation {
    condition = alltrue([
      for rule in var.security_rules :
      rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "Security rule priority must be between 100 and 4096."
  }

  ###############################################################
  # VALIDATION: direction
  # Description: Ensures direction is either Inbound or Outbound
  # Azure limits: Only these two values are valid
  ###############################################################
  validation {
    condition = alltrue([
      for rule in var.security_rules :
      contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "Direction must be 'Inbound' or 'Outbound'."
  }
}
