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
module "subnets_app" {
  source               = "./modules/Subnet"

  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name

  subnets = [
    {
      name             = "subnet-web"
      address_prefixes = ["10.0.1.0/24"]
      nsg_id           = module.nsg_web.id
      route_table_id   = module.rt_app.route_table_id
    },
    {
      name             = "subnet-app"
      address_prefixes = ["10.0.2.0/24"]
      nsg_id           = module.nsg_app.id
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    },
    {
      name             = "subnet-data"
      address_prefixes = ["10.0.3.0/24"]
      nsg_id           = module.nsg_data.id
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

### AKS Cluster Subnets

```hcl
module "subnets_aks" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name

  subnets = [
    {
      name             = "subnet-aks-nodes"
      address_prefixes = ["10.1.0.0/22"]
      nsg_id           = module.nsg_aks.id
      route_table_id   = module.rt_aks.route_table_id
      service_endpoints = ["Microsoft.Storage", "Microsoft.ContainerRegistry"]
    },
    {
      name             = "subnet-aks-pods"
      address_prefixes = ["10.1.4.0/22"]
    }
  ]
}
```

### Application Tier Subnets

```hcl
module "subnets_app_tier" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name

  subnets = [
    {
      name             = "subnet-web"
      address_prefixes = ["10.2.1.0/24"]
      nsg_id           = module.nsg_web.id
      route_table_id   = module.rt_app.route_table_id
      service_endpoints = ["Microsoft.KeyVault"]
    },
    {
      name             = "subnet-app"
      address_prefixes = ["10.2.2.0/24"]
      nsg_id           = module.nsg_app.id
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
    },
    {
      name             = "subnet-db"
      address_prefixes = ["10.2.3.0/24"]
      nsg_id           = module.nsg_db.id
    }
  ]
}
```

### Subnet with Azure SQL MI Delegation

```hcl
module "subnet_sqlmi" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name

  subnets = [
    {
      name             = "subnet-sqlmi"
      address_prefixes = ["10.3.1.0/24"]
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

### Subnet for Private Endpoints

```hcl
module "subnet_private_endpoints" {
  source               = "./modules/Subnet"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name

  subnets = [
    {
      name                               = "subnet-private-endpoints"
      address_prefixes                   = ["10.4.10.0/24"]
      private_endpoint_network_policies  = "Disabled"
    }
  ]
}
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
- **Route Table**: Associate to control traffic flow
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
