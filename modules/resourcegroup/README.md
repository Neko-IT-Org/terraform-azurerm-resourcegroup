# Azure Resource Group Terraform Module

This Terraform module creates and configures an Azure Resource Group with support for tags, management locks, and RBAC role assignments.

## Features

- Creates an Azure Resource Group
- Automatic `CreatedOn` tag with timestamp
- Support for management locks (CanNotDelete/ReadOnly)
- RBAC role assignment management
- Name validation according to Azure rules

## Usage

```hcl
module "rg" {
  source   = "./modules/resourcegroup"

  name     = "rg-neko-lab-weu-01"
  location = "westeurope"

  tags = {
    environment = "lab"
    project     = "palo-alto"
  }

  lock = {
    kind = "CanNotDelete"
    name = "rg-lock"
  }

  role_assignments = [
    {
      principal_id         = "00000000-0000-0000-0000-000000000000"
      role_definition_name = "Reader"
      description          = "Read-only access for monitoring"
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

| Name             | Description                                                                                    | Type           | Default | Required |
| ---------------- | ---------------------------------------------------------------------------------------------- | -------------- | ------- | :------: |
| name             | Resource group name (1-90 characters, alphanumerics, `_`, `-`, `.`, `()`, cannot end with `.`) | `string`       | n/a     |   yes    |
| location         | Azure region (e.g., `westeurope`)                                                              | `string`       | n/a     |   yes    |
| tags             | Custom tags (merged with `CreatedOn`)                                                          | `map(string)`  | `{}`    |    no    |
| lock             | Lock configuration (`kind`: `CanNotDelete`/`ReadOnly`, `name`: optional)                       | `object`       | `null`  |    no    |
| role_assignments | RBAC role assignments (see details below)                                                      | `list(object)` | `[]`    |    no    |

### role_assignments Object Structure

Each role assignment must contain:

- `principal_id` (required): Principal ID (user/group/service principal)
- `role_definition_id` OR `role_definition_name` (one required, mutually exclusive)
- `condition` (optional): ABAC condition
- `condition_version` (optional): Condition version
- `description` (optional): Assignment description
- `delegated_managed_identity_resource_id` (optional): Delegated MI resource ID

## Outputs

| Name     | Description                              |
| -------- | ---------------------------------------- |
| id       | Resource group ID                        |
| name     | Resource group name                      |
| location | Azure region                             |
| tags     | All applied tags (including `CreatedOn`) |

## Examples

### Simple Resource Group

```hcl
module "rg_simple" {
  source   = "./modules/resourcegroup"
  name     = "rg-app-prod-weu-01"
  location = "westeurope"

  tags = {
    environment = "production"
  }
}
```

### With Lock and Roles

```hcl
module "rg_secured" {
  source   = "./modules/resourcegroup"
  name     = "rg-hub-prod-weu-01"
  location = "westeurope"

  lock = {
    kind = "CanNotDelete"
  }

  role_assignments = [
    {
      principal_id         = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      role_definition_name = "Contributor"
    }
  ]

  tags = {
    environment = "production"
    criticality = "high"
  }
}
```

## Notes

- The `CreatedOn` tag is automatically added in `DD-MM-YYYY hh:mm` format
- Locks protect against accidental deletion/modification
- Validations ensure Azure naming compliance

## Resources Created

- `azurerm_resource_group` - The resource group
- `azurerm_management_lock` - Optional management lock
- `azurerm_role_assignment` - Optional RBAC assignments
- `time_static` - Timestamp for CreatedOn tag
