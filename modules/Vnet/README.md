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
module "vnet_hub" {
  source              = "./modules/Vnet"

  name                = "vnet-hub-neko-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg_hub.name

  address_space = ["10.0.0.0/16"]
  dns_servers   = ["10.0.0.4", "10.0.0.5"]

  tags = {
    environment = "lab"
    project     = "palo-alto-hub"
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

### Hub VNet for Palo Alto

```hcl
module "vnet_hub" {
  source              = "./modules/Vnet"
  name                = "vnet-hub-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg_hub.name

  address_space = ["10.0.0.0/16"]

  tags = {
    environment = "production"
    purpose     = "firewall-hub"
  }
}
```

### Spoke VNet with Custom DNS

```hcl
module "vnet_spoke" {
  source              = "./modules/Vnet"
  name                = "vnet-spoke-app-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg_spoke.name

  address_space = ["10.1.0.0/16"]
  dns_servers   = ["10.0.0.4"]  # Firewall DNS

  tags = {
    environment = "production"
    spoke       = "app"
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

  address_space           = ["10.2.0.0/16"]
  enable_ddos_protection  = true
  ddos_protection_plan_id = azurerm_network_ddos_protection_plan.main.id

  tags = {
    environment = "production"
    protected   = "true"
  }
}
```

## Notes

- The `CreatedOn` tag is automatically added
- If `address_space` is empty/null, VNet is created without CIDR (rare scenario)
- Default Azure DNS servers are used if not specified

## Resources Created

- `azurerm_virtual_network` - The virtual network
- `time_static` - Timestamp for CreatedOn tag
