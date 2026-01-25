# Azure Naming Terraform Module (Hybrid)

This Terraform module provides a hybrid naming solution that combines the official Azure naming module with custom naming capabilities for resources not covered by the standard module (like Palo Alto Networks resources).

## Features

- ✅ **Azure Official Naming**: Uses `Azure/naming/azurerm` for standard Azure resources
- ✅ **Custom Naming**: Support for custom resource types (Palo Alto, custom apps, etc.)
- ✅ **Consistent Convention**: Single naming standard across all resources
- ✅ **Validation**: Input validation for naming components
- ✅ **Flexibility**: Override/extend with custom resource types
- ✅ **Storage Sanitization**: Automatic name sanitization for storage accounts
- ✅ **Bulk Generation**: Generate multiple name variations with suffixes

## Naming Convention

### Standard Format
```
{prefix}-{resource_type}-{name}-{environment}-{region}-{suffix}
```

### Examples
- Resource Group: `neko-rg-hub-prod-weu-01`
- Virtual Network: `neko-vnet-hub-prod-weu-01`
- Palo Alto VM: `neko-palofw-hub-prod-weu-01`
- Storage Account: `nekostprodweu01` (sanitized)

## Usage

### Basic Usage (Azure Resources Only)

```hcl
module "naming" {
  source = "./modules/Naming"

  prefix      = "neko"
  suffix      = "01"
  environment = "prod"
  region      = "weu"
  
  unique_seed   = "myproject"
  unique_length = 4
}

# Use Azure naming module outputs
resource "azurerm_resource_group" "example" {
  name     = "${module.naming.resource_group_name}-hub"
  location = "westeurope"
}

resource "azurerm_virtual_network" "example" {
  name                = "${module.naming.virtual_network_name}-hub"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}
```

### Using Custom Resource Types (Palo Alto Example)

```hcl
module "naming" {
  source = "./modules/Naming"

  prefix      = "neko"
  suffix      = "01"
  environment = "prod"
  region      = "weu"
  
  # Enable Azure naming module
  use_azure_naming_module = true
  
  # Add custom resource types if needed (optional, built-in types already included)
  custom_resource_types = {
    "my_custom_app" = "app"
    "my_custom_db"  = "db"
  }
}

# Use Palo Alto naming (built-in custom type)
resource "azurerm_linux_virtual_machine" "palo_alto" {
  name                = "${module.naming.palo_alto_names.vm_series}-hub"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_D3_v2"
  
  # ... rest of configuration
}

# Use custom Palo Alto interface names
locals {
  palo_interfaces = {
    management = "${module.naming.custom_names.palo_alto_interface}-mgmt"
    untrust    = "${module.naming.custom_names.palo_alto_interface}-untrust"
    trust      = "${module.naming.custom_names.palo_alto_interface}-trust"
  }
}
```

### Generating Multiple Names with Suffixes

```hcl
module "naming" {
  source = "./modules/Naming"

  prefix      = "neko"
  environment = "prod"
  region      = "weu"
  
  # Generate multiple variations
  name_suffixes = ["mgmt", "untrust", "trust"]
}

# Access pre-built names
# module.naming.built_names.palo_alto_interface["mgmt"]
# module.naming.built_names.palo_alto_interface["untrust"]
# module.naming.built_names.palo_alto_interface["trust"]

resource "azurerm_network_interface" "palo_mgmt" {
  name                = module.naming.built_names.palo_alto_interface["mgmt"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  
  ip_configuration {
    name                          = "ipconfig-mgmt"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
  }
}
```

### Storage Account Naming

```hcl
module "naming" {
  source = "./modules/Naming"

  prefix      = "neko"
  suffix      = "01"
  environment = "prod"
  region      = "weu"
  unique_seed = "bootstrap"
}

# Storage account names are automatically sanitized
resource "azurerm_storage_account" "bootstrap" {
  name                     = module.naming.storage_account_name
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

## Requirements

| Name      | Version   |
| --------- | --------- |
| terraform | >= 1.5.0  |
| azurerm   | >= 3.70.0 |
| null      | >= 3.0.0  |

## Modules

| Name          | Source                     | Version |
| ------------- | -------------------------- | ------- |
| azure_naming  | Azure/naming/azurerm       | ~> 0.4.0|

## Inputs

| Name                      | Description                                           | Type          | Default                                          | Required |
| ------------------------- | ----------------------------------------------------- | ------------- | ------------------------------------------------ | :------: |
| prefix                    | Prefix for all resource names                         | `string`      | `null`                                           |    no    |
| suffix                    | Suffix for all resource names                         | `string`      | `null`                                           |    no    |
| environment               | Environment (dev, test, staging, prod, etc.)          | `string`      | `null`                                           |    no    |
| region                    | Azure region short name (weu, eus, frc, etc.)         | `string`      | `null`                                           |    no    |
| unique_seed               | Seed for generating unique names                      | `string`      | `""`                                             |    no    |
| unique_length             | Length of unique suffix (1-8)                         | `number`      | `4`                                              |    no    |
| custom_resource_types     | Additional custom resource types                      | `map(string)` | `{}`                                             |    no    |
| name_suffixes             | List of suffixes for bulk name generation             | `list(string)`| `[]`                                             |    no    |
| validate_names            | Enable naming validation                              | `bool`        | `true`                                           |    no    |
| use_azure_naming_module   | Use Azure official naming module                      | `bool`        | `true`                                           |    no    |
| naming_convention_format  | Custom naming convention format                       | `string`      | `"{prefix}-{type}-{name}-{env}-{region}-{suffix}"`|    no    |

## Outputs

| Name                        | Description                                      |
| --------------------------- | ------------------------------------------------ |
| azure_names                 | Names from Azure official module                 |
| custom_names                | Custom resource names                            |
| all_names                   | Combined Azure + custom names                    |
| storage_names               | Sanitized storage account names                  |
| palo_alto_names             | Palo Alto specific names                         |
| naming_components           | Individual naming components                     |
| built_names                 | Pre-built names with suffixes                    |
| resource_group_name         | Convenience: RG name                             |
| virtual_network_name        | Convenience: VNet name                           |
| subnet_name                 | Convenience: Subnet name                         |
| network_security_group_name | Convenience: NSG name                            |
| route_table_name            | Convenience: Route Table name                    |
| public_ip_name              | Convenience: Public IP name                      |
| virtual_machine_name        | Convenience: VM name                             |
| storage_account_name        | Convenience: Storage Account name (sanitized)    |
| key_vault_name              | Convenience: Key Vault name                      |
| palo_alto_vm_name           | Convenience: Palo Alto VM name                   |

## Built-in Custom Resource Types

The module includes built-in support for these custom resource types:

### Palo Alto Networks
- `palo_alto_vm_series` → `palofw`
- `palo_alto_management_profile` → `paloprf`
- `palo_alto_interface` → `paloif`
- `palo_alto_zone` → `palozone`
- `palo_alto_virtual_router` → `palovr`
- `palo_alto_security_policy` → `palopol`

### Azure Resources (not in official module)
- `route_table_route` → `route`
- `nsg_security_rule` → `nsgr`
- `subnet_nsg_association` → `snsga`
- `subnet_rt_association` → `srta`

### Generic Custom Resources
- `custom_vm` → `vm`
- `custom_nic` → `nic`
- `custom_disk` → `disk`
- `custom_pip` → `pip`

## Examples

### Complete Hub-and-Spoke with Palo Alto

```hcl
module "naming" {
  source = "./modules/Naming"

  prefix      = "neko"
  suffix      = "01"
  environment = "prod"
  region      = "weu"
  
  name_suffixes = ["hub", "spoke-app", "spoke-data"]
}

# Resource Group
module "rg_hub" {
  source   = "./modules/resourcegroup"
  name     = "${module.naming.resource_group_name}-hub"
  location = "westeurope"
  tags     = { environment = "production" }
}

# Hub VNet
module "vnet_hub" {
  source              = "./modules/Vnet"
  name                = "${module.naming.virtual_network_name}-hub"
  location            = module.rg_hub.location
  resource_group_name = module.rg_hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = { purpose = "hub-network" }
}

# Palo Alto VM
resource "azurerm_linux_virtual_machine" "palo_alto" {
  name                = "${module.naming.palo_alto_names.vm_series}-hub"
  resource_group_name = module.rg_hub.name
  location            = module.rg_hub.location
  size                = "Standard_D3_v2"
  
  admin_username = "panadmin"
  
  network_interface_ids = [
    azurerm_network_interface.mgmt.id,
    azurerm_network_interface.untrust.id,
    azurerm_network_interface.trust.id,
  ]
  
  # ... rest of configuration
}
```

### Extending with Your Own Custom Types

```hcl
module "naming" {
  source = "./modules/Naming"

  prefix      = "mycompany"
  environment = "prod"
  region      = "weu"
  
  # Add your own custom types
  custom_resource_types = {
    "fortinet_firewall"     = "fgfw"
    "checkpoint_firewall"   = "cpfw"
    "nginx_ingress"         = "nginx"
    "redis_cache"           = "redis"
    "mongodb_cluster"       = "mongo"
    "elasticsearch_cluster" = "elastic"
  }
}

# Use your custom types
resource "azurerm_linux_virtual_machine" "fortinet" {
  name = "${module.naming.custom_names.fortinet_firewall}-hub"
  # ...
}
```

## Best Practices

1. **Consistent Prefixes**: Use company/project name as prefix
2. **Environment Codes**: Use short codes (dev, prod) not full names
3. **Region Codes**: Use 3-4 letter codes (weu, eus, frc)
4. **Suffix for Instances**: Use 01, 02, etc. for multiple instances
5. **Validation**: Keep `validate_names = true` to catch errors early
6. **Storage Names**: Always use the module's storage_account_name output (automatically sanitized)

## Naming Limitations

### Azure Resource Name Constraints

Different Azure resources have different naming constraints:

| Resource Type       | Max Length | Allowed Characters              | Case     |
| ------------------- | ---------- | ------------------------------- | -------- |
| Resource Group      | 90         | Alphanumeric, `_`, `-`, `.`, `()`| Any      |
| Virtual Network     | 64         | Alphanumeric, `_`, `-`, `.`     | Any      |
| Subnet              | 80         | Alphanumeric, `_`, `-`, `.`     | Any      |
| NSG                 | 80         | Alphanumeric, `_`, `-`, `.`     | Any      |
| VM                  | 64         | Alphanumeric, `-`               | Any      |
| Storage Account     | 24         | Alphanumeric only               | Lowercase|
| Key Vault           | 24         | Alphanumeric, `-`               | Any      |

This module automatically handles these constraints.

## Troubleshooting

### Name Too Long
```
Error: Name exceeds maximum length
```
**Solution**: Shorten prefix, suffix, or use shorter region codes.

### Invalid Characters in Storage Name
```
Error: Storage account name contains invalid characters
```
**Solution**: Use `module.naming.storage_account_name` which is automatically sanitized.

### Custom Resource Type Not Found
```
Error: lookup failed
```
**Solution**: Add your custom type to `custom_resource_types` variable or use built-in types.

## Migration from Azure Naming Module Only

If you're currently using only the Azure naming module:

```hcl
# Before
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.0"
  
  prefix = "neko"
  suffix = "01"
}

# After (no changes needed to resource references!)
module "naming" {
  source = "./modules/Naming"
  
  prefix      = "neko"
  suffix      = "01"
  environment = "prod"
  region      = "weu"
}

# Your existing resources still work
resource "azurerm_resource_group" "example" {
  name     = module.naming.resource_group_name
  location = "westeurope"
}
```

## Authors

Neko-IT-Org

## License

This module is maintained by Neko-IT-Org for use in Azure infrastructure projects.
