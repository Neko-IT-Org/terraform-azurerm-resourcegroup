# Azure Network Security Group (NSG) Terraform Module

This Terraform module creates and configures an Azure Network Security Group with customizable security rules.

## Features

- Creates an NSG with security rules
- Support for inbound/outbound rules
- Automatic priority validation (100-4096)
- Direction validation (Inbound/Outbound)
- Automatic `CreatedOn` tag with timestamp

## Usage

```hcl
module "nsg_app" {
  source              = "./modules/NSG"

  name                = "nsg-app-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  security_rules = [
    {
      name                       = "Allow-HTTPS-Inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
      description                = "Allow HTTPS from internal network"
    }
  ]

  tags = {
    environment = "production"
    application = "web"
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

| Name                | Description                                | Type           | Default | Required |
| ------------------- | ------------------------------------------ | -------------- | ------- | :------: |
| name                | NSG name                                   | `string`       | n/a     |   yes    |
| location            | Azure region                               | `string`       | n/a     |   yes    |
| resource_group_name | Resource group name                        | `string`       | n/a     |   yes    |
| tags                | Custom tags                                | `map(string)`  | n/a     |   yes    |
| security_rules      | List of security rules (see details below) | `list(object)` | n/a     |   yes    |

### security_rules Object Structure

Each rule must contain:

- `name` (required): Rule name
- `priority` (required): Priority (100-4096, validated automatically)
- `direction` (required): `Inbound` or `Outbound` (validated automatically)
- `access` (required): `Allow` or `Deny`
- `protocol` (required): `Tcp`, `Udp`, `Icmp`, or `*`
- `source_port_range` (optional): Single source port (e.g., `"80"`, `"*"`)
- `destination_port_range` (optional): Single destination port
- `source_address_prefix` (optional): Single source address (e.g., `"10.0.0.0/8"`)
- `destination_address_prefix` (optional): Single destination address
- `source_port_ranges` (optional): List of source ports
- `destination_port_ranges` (optional): List of destination ports
- `source_address_prefixes` (optional): List of source addresses
- `destination_address_prefixes` (optional): List of destination addresses
- `description` (optional): Rule description

## Outputs

| Name                | Description            |
| ------------------- | ---------------------- |
| id                  | NSG ID                 |
| name                | NSG name               |
| security_rule       | Applied security rules |
| location            | Azure region           |
| resource_group_name | Resource group name    |

## Examples

### NSG for AKS Cluster

```hcl
module "nsg_aks" {
  source              = "./modules/NSG"
  name                = "nsg-aks-cluster-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  security_rules = [
    {
      name                       = "Allow-Kube-API"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
      description                = "Allow Kubernetes API access"
    },
    {
      name                       = "Deny-All-Inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound"
    }
  ]

  tags = {
    environment = "production"
    workload    = "kubernetes"
  }
}
```

### NSG for Database Tier

```hcl
module "nsg_database" {
  source              = "./modules/NSG"
  name                = "nsg-db-prod-weu-01"
  location            = "westeurope"
  resource_group_name = module.rg.name

  security_rules = [
    {
      name                       = "Allow-SQL"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefixes    = ["10.1.10.0/24", "10.1.20.0/24"]
      destination_address_prefix = "*"
      description                = "Allow SQL from app subnets"
    },
    {
      name                       = "Allow-PostgreSQL"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.1.0.0/16"
      destination_address_prefix = "*"
      description                = "Allow PostgreSQL from VNet"
    }
  ]

  tags = {
    environment = "production"
    tier        = "database"
  }
}
```

## Best Practices

- **Explicit Deny**: Always end with a Deny-All rule at priority 4096
- **Least Privilege**: Only allow what is strictly necessary
- **Descriptions**: Document each rule for audit purposes
- **Service Tags**: Use Azure service tags when possible (e.g., `Internet`, `VirtualNetwork`)
- **No Any/Any**: Avoid `*/*` rules except for explicit deny

## Notes

- Priorities must be unique and between 100-4096
- Rules are evaluated in ascending priority order
- The `CreatedOn` tag is automatically added

## Resources Created

- `azurerm_network_security_group` - The network security group
- `time_static` - Timestamp for CreatedOn tag
