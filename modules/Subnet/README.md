# Subnet Terraform Module

This module creates multiple Azure subnets and associates them with network security groups (NSGs) if provided.

## Features

- Creates multiple subnets using a list variable
- Supports service endpoints, delegations, IP address pools
- Associates NSGs to subnets if specified
- Handles optional subnet features via variables

## Usage

```hcl
module "subnet" {
	source                = "./modules/Subnet"
	resource_group_name   = "my-rg"
	virtual_network_name  = "my-vnet"
	subnets = [
		{
			name                 = "subnet1"
			address_prefixes     = ["10.0.1.0/24"]
			nsg_id               = azurerm_network_security_group.nsg1.id
			service_endpoints    = ["Microsoft.Storage"]
			delegations = [
				{
					name = "delegation1"
					service_delegation = {
						name    = "Microsoft.Sql/servers"
						actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
					}
				}
			]
		},
		{
			name                 = "subnet2"
			address_prefixes     = ["10.0.2.0/24"]
		}
	]
}
```

## Input Variables

- `resource_group_name` (string): Name of the resource group
- `virtual_network_name` (string): Name of the virtual network
- `subnets` (list): List of subnet objects with properties:
  - `name` (string): Subnet name
  - `address_prefixes` (list(string), optional): Address prefixes
  - `nsg_id` (string, optional): NSG ID to associate
  - `service_endpoints` (list(string), optional): Service endpoints
  - `route_table_id` (string, optional): Route table ID
  - `ip_address_pool` (object, optional): IP address pool config
  - `private_endpoint_network_policies_enabled` (bool, optional)
  - `default_outbound_access_enabled` (bool, optional)
  - `delegations` (list(object), optional): Delegation configs

## Outputs

- `snet-name`: Map of subnet names to subnet IDs

## Recommendations & Best Practices

- Add a `tags` variable and apply tags to subnets for better management and cost tracking.
- Consider adding support for associating route tables to subnets if `route_table_id` is provided.
- Add variable validation rules to ensure required fields are set (e.g., `address_prefixes` should not be empty).
- Output more attributes, such as subnet address prefixes and resource group, if useful for consumers.
- Pin the AzureRM provider version in your root module to avoid breaking changes.
- Document NSG usage and ensure only required ports/services are allowed.

## Requirements

- Terraform >= 1.0
- AzureRM provider >= 3.0

## License

MIT
