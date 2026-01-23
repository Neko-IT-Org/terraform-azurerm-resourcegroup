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
module "rg_app" {
  source   = "./modules/resourcegroup"

  name     = "rg-app-prod-weu-01"
  location = "westeurope"

  tags = {
    environment = "production"
    application = "webapp"
    costcenter  = "it-ops"
  }

  lock = {
    kind = "CanNotDelete"
    name = "prevent-deletion"
  }

  role_assignments = [
    {
      principal_id         = "00000000-0000-0000-0000-000000000000"
      role_definition_name = "Reader"
      description          = "Read-only access for monitoring team"
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
  name     = "rg-myapp-dev-weu-01"
  location = "westeurope"

  tags = {
    environment = "development"
  }
}
```

### Resource Group with Lock

```hcl
module "rg_locked" {
  source   = "./modules/resourcegroup"
  name     = "rg-critical-prod-weu-01"
  location = "westeurope"

  lock = {
    kind = "CanNotDelete"
    name = "critical-resource-lock"
  }

  tags = {
    environment = "production"
    criticality = "high"
  }
}
```

### Resource Group with RBAC

```hcl
module "rg_rbac" {
  source   = "./modules/resourcegroup"
  name     = "rg-shared-prod-weu-01"
  location = "westeurope"

  role_assignments = [
    {
      principal_id         = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      role_definition_name = "Contributor"
      description          = "Dev team full access"
    },
    {
      principal_id         = "bbbbbbbb-cccc-dddd-eeee-ffffffffffff"
      role_definition_name = "Reader"
      description          = "Monitoring team read access"
    }
  ]

  tags = {
    environment = "production"
    shared      = "true"
  }
}
```

### Resource Group for AKS

```hcl
module "rg_aks" {
  source   = "./modules/resourcegroup"
  name     = "rg-aks-cluster-prod-weu-01"
  location = "westeurope"

  lock = {
    kind = "CanNotDelete"
  }

  tags = {
    environment = "production"
    workload    = "kubernetes"
    managed_by  = "terraform"
  }
}
```

### Multi-Environment Resource Groups

```hcl
locals {
  environments = ["dev", "staging", "prod"]
}

module "rg_environments" {
  for_each = toset(local.environments)

  source   = "./modules/resourcegroup"
  name     = "rg-app-${each.key}-weu-01"
  location = "westeurope"

  lock = each.key == "prod" ? {
    kind = "CanNotDelete"
  } : null

  tags = {
    environment = each.key
    application = "webapp"
  }
}
```

## Use Cases

- **Application Hosting**: Group resources by application or workload
- **Environment Separation**: Separate resource groups for dev, staging, prod
- **Cost Management**: Track costs per resource group with tags
- **Access Control**: Apply RBAC at resource group level
- **Lifecycle Management**: Group resources with similar lifecycles

## Best Practices

- **Naming Convention**: Use consistent naming (resource-app-env-region-index)
- **Tagging Strategy**: Include environment, cost center, owner tags
- **Lock Critical RGs**: Protect production resource groups with CanNotDelete lock
- **RBAC Granularity**: Apply least privilege principle with role assignments
- **Regional Consistency**: Keep resources in same region as their RG when possible

## Notes

- The `CreatedOn` tag is automatically added in `DD-MM-YYYY hh:mm` format
- Locks protect against accidental deletion/modification
- Validations ensure Azure naming compliance
- Resource group location doesn't restrict resource locations

## Resources Created

- `azurerm_resource_group` - The resource group
- `azurerm_management_lock` - Optional management lock
- `azurerm_role_assignment` - Optional RBAC assignments
- `time_static` - Timestamp for CreatedOn tag
