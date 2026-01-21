# terraform-azurerm-resourcegroup

Terraform module to create and manage an Azure Resource Group with optional tags and lock.

## Usage

```hcl
module "rg" {
  source   = "kissho-academy/resourcegroup/azurerm"
  version  = "1.0.1"

  name     = "rg-app-prod-westeurope"
  location = "westeurope"

  tags = {
    environment = "prod"
    owner       = "team"
  }

  lock = {
    kind = "CanNotDelete"
    name = "rg-lock"
  }
}
```
