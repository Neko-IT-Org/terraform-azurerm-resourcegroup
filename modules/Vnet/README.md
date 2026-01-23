# Azure Virtual Network (VNet) Terraform Module

This Terraform module creates and configures an Azure Virtual Network with support for DDoS Protection, custom DNS, and IP Address Pools.

## Features

- Creates a VNet with configurable address space
- Optional DDoS Protection Plan support
- Custom DNS server configuration
- IP Address Pool (IPAM) support
- Automatic `CreatedOn` tag with timestamp

## Usage

```hcl
module "vnet_app" {
  source              = "./modules/Vnet"

  name                = "vnet-app-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  address_space = ["10.1.0.0/16"]
  dns_servers   = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "production"
    application = "webapp"
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

| Name                    | Description                           | Type           | Default | Required |
| ----------------------- | ------------------------------------- | -------------- | ------- | :------: |
| name                    | VNet name                             | `string`       | n/a     |   yes    |
| location                | Azure region                          | `string`       | n/a     |   yes    |
| resource_group_name     | Resource group name                   | `string`       | n/a     |   yes    |
| tags                    | Custom tags                           | `map(string)`  | n/a     |   yes    |
| address_space           | CIDR blocks (e.g., `["10.0.0.0/16"]`) | `list(string)` | `null`  |    no    |
| dns_servers             | Custom DNS server IPs                 | `list(string)` | `null`  |    no    |
| enable_ddos_protection  | Enable DDoS Protection Plan           | `bool`         | `false` |    no    |
| ddos_protection_plan_id | DDoS Protection Plan ID               | `string`       | `null`  |    no    |
| ip_address_pool         | IPAM pool configuration               | `object`       | `null`  |    no    |

### ip_address_pool Object Structure

```hcl
ip_address_pool = {
  id                     = "/subscriptions/.../ipamPools/pool1"
  number_of_ip_addresses = "256"
}
```

## Outputs

| Name                | Description         |
| ------------------- | ------------------- |
| id                  | VNet ID             |
| name                | VNet name           |
| resource_group_name | Resource group name |
| location            | Azure region        |
| tags                | All applied tags    |

## Examples

### Simple VNet

```hcl
module "vnet_app" {
  source              = "./modules/Vnet"
  name                = "vnet-app-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  address_space = ["10.1.0.0/16"]

  tags = {
    environment = "production"
    workload    = "application"
  }
}
```

### VNet with Custom DNS

```hcl
module "vnet_spoke" {
  source              = "./modules/Vnet"
  name                = "vnet-spoke-dev-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  address_space = ["10.2.0.0/16"]
  dns_servers   = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "development"
    purpose     = "spoke-network"
  }
}
```

### VNet with DDoS Protection

```hcl
module "vnet_protected" {
  source              = "./modules/Vnet"
  name                = "vnet-prod-protected-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  address_space           = ["10.3.0.0/16"]
  enable_ddos_protection  = true
  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.main.id

  tags = {
    environment = "production"
    protected   = "true"
  }
}
```

### VNet for AKS Cluster

```hcl
module "vnet_aks" {
  source              = "./modules/Vnet"
  name                = "vnet-aks-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  address_space = ["10.10.0.0/16"]

  tags = {
    environment = "production"
    workload    = "kubernetes"
  }
}
```

### Multi-Region VNet

```hcl
module "vnet_dr" {
  source              = "./modules/Vnet"
  name                = "vnet-app-prod-eus-01"
  location            = "eastus"
  resource_group_name = module.rg_dr.name

  address_space = ["10.20.0.0/16"]

  tags = {
    environment = "production"
    region      = "dr"
  }
}
```

## Use Cases

- **Hub-and-Spoke**: Central hub VNet with multiple spoke VNets
- **AKS**: Dedicated VNet for Kubernetes clusters
- **Multi-Tier Apps**: Separate VNets for web, app, data tiers
- **Isolation**: Isolated VNets for different environments (dev, staging, prod)
- **PaaS Integration**: VNets with service endpoints for Azure PaaS services

## Best Practices

- **Address Space Planning**: Reserve sufficient address space for future growth
- **DNS Configuration**: Use custom DNS for hybrid scenarios, Azure default for cloud-only
- **Segmentation**: One VNet per workload or environment for isolation
- **DDoS Protection**: Enable for production workloads exposed to internet
- **Naming Convention**: Include purpose, environment, and region in VNet name

## Notes

- The `CreatedOn` tag is automatically added
- If `address_space` is empty/null, VNet is created without CIDR (rare scenario)
- Default Azure DNS servers are used if not specified
- VNet peering must be configured separately

## Resources Created

- `azurerm_virtual_network` - The virtual network
- `time_static` - Timestamp for CreatedOn tag
