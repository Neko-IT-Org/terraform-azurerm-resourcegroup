# Azure Subnet Terraform Module

This Terraform module creates and configures multiple Azure subnets with support for NSG, Route Tables, Service Endpoints, and Delegations.

## Features

- Creates multiple subnets within a VNet
- Automatic NSG association
- Automatic Route Table association
- Service Endpoints support
- Delegations support (for Azure managed services)
- IP Address Pools (IPAM) support
- Private Endpoint Network Policies configuration
- Outbound Access configuration

## Usage

```hcl
module "subnets_hub" {
  source               = "./modules/Subnet"

  resource_group_name  = module.rg_hub.name
  virtual_network_name = module.vnet_hub.name

  subnets = [
    {
      name             = "subnet-mgmt"
      address_prefixes = ["10.0.0.0/24"]
      nsg_id           = module.nsg_mgmt.id
    },
    {
      name             = "subnet-untrust"
      address_prefixes = ["10.0.1.0/24"]
      nsg_id           = module.nsg_untrust.id
      route_table_id   = module.rt_untrust.route_table_id
    },
    {
      name             = "subnet-trust"
      address_prefixes = ["10.0.2.0/24"]
      route_table_id   = module.rt_trust.route_table_id
    }
  ]
}
```

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.5.0  |
| azurerm   | >= 3.70.0 |
| time      | >= 0.9.0  |

## Providers

| Name    | Version   |
| ------- | --------- |
| azurerm | >= 3.70.0 |
| time    | >= 0.9.0  |

## Inputs

| Name                 | Description                                   | Type           | Required |
| -------------------- | --------------------------------------------- | -------------- | :------: |
| resource_group_name  | Resource group name                           | `string`       |   yes    |
| virtual_network_name | Parent VNet name                              | `string`       |   yes    |
| subnets              | List of subnets to create (see details below) | `list(object)` |   yes    |

### subnets Object Structure

Each subnet can contain:

- `name` (required): Subnet name
- `address_prefixes` (optional): CIDR list (e.g., `["10.0.1.0/24"]`)
- `nsg_id` (optional): NSG ID to associate
- `route_table_id` (optional): Route Table ID to associate
- `service_endpoints` (optional): Service endpoints list (e.g., `["Microsoft.Storage"]`)
- `private_endpoint_network_policies` (optional): `"Enabled"` or `"Disabled"` (string)
- `default_outbound_access_enabled` (optional): `true` or `false` (default: `false`)
- `ip_address_pool` (optional): IPAM pool configuration
- `delegations` (optional): Delegation list for managed services

### ip_address_pool Structure

```hcl
ip_address_pool = {
  id                     = "/subscriptions/.../ipamPools/pool1"
  number_of_ip_addresses = 256
}
```

### delegations Structure

```hcl
delegations = [
  {
    name = "delegation1"
    service_delegation = {
      name    = "Microsoft.Sql/managedInstances"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
]
```

## Outputs

| Name                 | Description                                          |
| -------------------- | ---------------------------------------------------- |
| name                 | Map of subnet names (key: name, value: name)         |
| id                   | Map of subnet IDs (key: name, value: ID)             |
| address_prefixes     | Map of address prefixes (key: name, value: prefixes) |
| virtual_network_name | Parent VNet name                                     |

## Examples

### Hub Subnets for Palo Alto

```hcl
module "subnets_hub_firewall" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg_hub.name
  virtual_network_name = module.vnet_hub.name

  subnets = [
    {
      name             = "subnet-management"
      address_prefixes = ["10.0.0.0/26"]
      nsg_id           = module.nsg_mgmt.id
    },
    {
      name                              = "subnet-untrust"
      address_prefixes                  = ["10.0.1.0/26"]
      route_table_id                    = module.rt_untrust.route_table_id
      default_outbound_access_enabled   = true
    },
    {
      name             = "subnet-trust"
      address_prefixes = ["10.0.2.0/26"]
      route_table_id   = module.rt_trust.route_table_id
    }
  ]
}
```

### Subnet with Service Endpoints

```hcl
module "subnet_app" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg_spoke.name
  virtual_network_name = module.vnet_spoke.name

  subnets = [
    {
      name             = "subnet-app"
      address_prefixes = ["10.1.1.0/24"]
      nsg_id           = module.nsg_app.id
      route_table_id   = module.rt_spoke.route_table_id
      service_endpoints = [
        "Microsoft.Storage",
        "Microsoft.KeyVault",
        "Microsoft.Sql"
      ]
    }
  ]
}
```

### Subnet with Delegation (Azure SQL MI)

```hcl
module "subnet_sqlmi" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg_data.name
  virtual_network_name = module.vnet_data.name

  subnets = [
    {
      name             = "subnet-sqlmi"
      address_prefixes = ["10.2.1.0/24"]
      nsg_id           = module.nsg_sqlmi.id
      route_table_id   = module.rt_sqlmi.route_table_id
      delegations = [
        {
          name = "sqlmi-delegation"
          service_delegation = {
            name = "Microsoft.Sql/managedInstances"
            actions = [
              "Microsoft.Network/virtualNetworks/subnets/join/action",
              "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
              "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
            ]
          }
        }
      ]
    }
  ]
}
```

### Subnet with Private Endpoints

```hcl
module "subnet_private_endpoints" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg_spoke.name
  virtual_network_name = module.vnet_spoke.name

  subnets = [
    {
      name                               = "subnet-private-endpoints"
      address_prefixes                   = ["10.1.10.0/24"]
      private_endpoint_network_policies  = "Disabled"
    }
  ]
}
```

## Typical Hub-and-Spoke Architecture

### Hub (Firewall)

```
VNet Hub: 10.0.0.0/16
├── subnet-management (10.0.0.0/26)   → Strict NSG, no route table
├── subnet-untrust    (10.0.1.0/26)   → Route to Internet, permissive NSG
└── subnet-trust      (10.0.2.0/26)   → Route to Spokes
```

### Spoke

```
VNet Spoke: 10.1.0.0/16
├── subnet-app        (10.1.1.0/24)   → App NSG, Route to FW, Service Endpoints
├── subnet-data       (10.1.2.0/24)   → Data NSG, Route to FW
└── subnet-pe         (10.1.10.0/24)  → Private Endpoints, policies disabled
```

## Available Service Endpoints

- `Microsoft.Storage`
- `Microsoft.Sql`
- `Microsoft.KeyVault`
- `Microsoft.ContainerRegistry`
- `Microsoft.ServiceBus`
- `Microsoft.EventHub`
- `Microsoft.CognitiveServices`
- `Microsoft.Web`
- `Microsoft.AzureCosmosDB`

## Best Practices

- **Sizing**: Plan for growth (avoid /30, /29)
- **Segmentation**: One subnet per tier (web, app, data)
- **NSG**: Always associate an NSG (except GatewaySubnet)
- **Route Table**: Associate to force traffic through firewall
- **Private Endpoints**: Dedicate a subnet with policies disabled
- **Delegations**: One dedicated subnet per managed service

## Limitations

- Subnets **do NOT support tags** directly (Azure limitation)
- Some Azure services require minimum subnet sizes
- Delegations make the subnet exclusive to the delegated service

## Notes

- NSG/Route Table association is automatic if ID is provided
- Subnet names must be unique within the VNet
- GatewaySubnet, AzureFirewallSubnet have special constraints

## Resources Created

- `azurerm_subnet` - The subnets
- `azurerm_subnet_network_security_group_association` - NSG associations (if nsg_id provided)
- `azurerm_subnet_route_table_association` - Route Table associations (if route_table_id provided)
