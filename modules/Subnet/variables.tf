# Name of the resource group in which the subnet will be created.
variable "resource_group_name" { type = string }

# Name of the virtual network to which the subnet belongs.
variable "virtual_network_name" { type = string }

# List of subnet objects to be created within the virtual network. Each object can specify name, address prefixes, NSG, service endpoints, route table, IPAM pool, network policies, outbound access, and delegations.
variable "subnets" {
  type = list(object({
    name              = string
    address_prefixes  = optional(list(string))
    nsg_id            = optional(string)
    service_endpoints = optional(list(string))
    route_table_id    = optional(string)
    ip_address_pool = optional(object({
      id                     = string
      number_of_ip_addresses = number
    }))
    private_endpoint_network_policies = optional(bool)
    default_outbound_access_enabled   = optional(bool, false)
    delegations = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
  }))
}
