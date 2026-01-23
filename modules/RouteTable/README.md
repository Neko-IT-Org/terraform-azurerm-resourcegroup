# Azure Route Table Terraform Module

This Terraform module creates and configures an Azure Route Table with custom routes for network routing.

## Features

- Creates a Route Table with defined routes
- BGP route propagation support
- Automatic next hop type validation
- Next hop IP validation for VirtualAppliance
- Automatic `CreatedOn` tag with timestamp

## Usage

```hcl
module "rt_app" {
  source              = "./modules/RouteTable"

  name                = "rt-app-spoke-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  bgp_route_propagation_enabled = false

  route = [
    {
      name                   = "default-route"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.100.4"
    }
  ]

  tags = {
    environment = "production"
    spoke       = "app"
  }
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

| Name                          | Description                        | Type           | Default | Required |
| ----------------------------- | ---------------------------------- | -------------- | ------- | :------: |
| name                          | Route Table name                   | `string`       | n/a     |   yes    |
| location                      | Azure region                       | `string`       | n/a     |   yes    |
| resource_group_name           | Resource group name                | `string`       | n/a     |   yes    |
| bgp_route_propagation_enabled | Enable BGP route propagation       | `bool`         | `true`  |    no    |
| route                         | List of routes (see details below) | `list(object)` | n/a     |   yes    |
| tags                          | Custom tags                        | `map(string)`  | `{}`    |    no    |

### route Object Structure

Each route must contain:

- `name` (required): Route name
- `address_prefix` (required): Destination CIDR (e.g., `"0.0.0.0/0"`)
- `next_hop_type` (required): Next hop type (validated automatically)
  - `VirtualNetworkGateway`: VPN/ExpressRoute Gateway
  - `VnetLocal`: Local VNet routing
  - `Internet`: To Internet
  - `VirtualAppliance`: NVA (Network Virtual Appliance)
  - `None`: Blackhole route
- `next_hop_in_ip_address` (required if `VirtualAppliance`): NVA IP address

**Automatic Validation**: If `next_hop_type = "VirtualAppliance"`, then `next_hop_in_ip_address` is mandatory.

## Outputs

| Name              | Description       |
| ----------------- | ----------------- |
| route_table_id    | Route Table ID    |
| route_table_name  | Route Table name  |
| route_table_route | Configured routes |

## Examples

### Route Table for AKS Egress Control

```hcl
module "rt_aks_egress" {
  source              = "./modules/RouteTable"
  name                = "rt-aks-cluster-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  bgp_route_propagation_enabled = false

  route = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = "10.0.100.4"
    },
    {
      name                   = "azure-services"
      address_prefix         = "168.63.129.16/32"
      next_hop_type          = "Internet"
    }
  ]

  tags = {
    environment = "production"
    workload    = "kubernetes"
  }
}
```

### Route Table for Internet Egress

```hcl
module "rt_internet" {
  source              = "./modules/RouteTable"
  name                = "rt-public-subnet-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  bgp_route_propagation_enabled = false

  route = [
    {
      name           = "to-internet"
      address_prefix = "0.0.0.0/0"
      next_hop_type  = "Internet"
    }
  ]

  tags = {
    environment = "production"
    purpose     = "public-egress"
  }
}
```

### Route Table for ExpressRoute

```hcl
module "rt_expressroute" {
  source              = "./modules/RouteTable"
  name                = "rt-gateway-subnet-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  bgp_route_propagation_enabled = true

  route = [
    {
      name           = "to-onprem"
      address_prefix = "192.168.0.0/16"
      next_hop_type  = "VirtualNetworkGateway"
    }
  ]

  tags = {
    environment = "production"
    connectivity = "expressroute"
  }
}
```

### Route Table with Blackhole

```hcl
module "rt_blackhole" {
  source              = "./modules/RouteTable"
  name                = "rt-isolation-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  bgp_route_propagation_enabled = false

  route = [
    {
      name           = "blackhole-private"
      address_prefix = "10.0.0.0/8"
      next_hop_type  = "None"
    }
  ]

  tags = {
    environment = "production"
    purpose     = "isolation"
  }
}
```

## Best Practices

- **BGP Propagation**: Disable (`false`) in spoke VNets to avoid routing loops
- **Next Hop IP**: Use the private IP of your NVA (firewall, router, etc.)
- **Default Route**: Configure `0.0.0.0/0` based on your security requirements
- **Segmentation**: Create one Route Table per network function

## Notes

- The `CreatedOn` tag is automatically added
- Routes are evaluated by longest prefix match
- Validations prevent configuration errors

## Resources Created

- `azurerm_route_table` - The route table
- `time_static` - Timestamp for CreatedOn tag
