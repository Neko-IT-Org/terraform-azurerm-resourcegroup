# 🔐 Azure Key Vault Terraform Module

Terraform module to deploy a **secure Azure Key Vault** with support for **Network ACLs**, **RBAC**, and **telemetry**.

> ⚠️ **Note**: Ce module ne crée PAS de Private Endpoint. Utilisez le module `PrivateEndpoint` séparé pour une architecture plus flexible et maintenable.

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Usage](#-usage)
- [Variables](#-variables)
- [Outputs](#-outputs)
- [Examples](#-examples)
- [Private Endpoint Integration](#-private-endpoint-integration)
- [Security Best Practices](#-security-best-practices)

---

## 🎯 Overview

This module deploys a **production-ready Azure Key Vault** including:

- ✅ **RBAC** (Role-Based Access Control) - recommended
- ✅ **Network ACLs** for network access control
- ✅ **Soft Delete** with purge protection
- ✅ **Telemetry** to Log Analytics
- ✅ **Encryption** support for disks, deployments, ARM templates
- ✅ **Automatic tagging** with creation timestamp

### What This Module Does NOT Include

- ❌ Private Endpoint (use `modules/PrivateEndpoint` separately)
- ❌ Private DNS Zone (create separately)
- ❌ Secrets/Keys/Certificates (use `modules/KeyVault-Key` or manage separately)

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Key Vault                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ SKU: Standard / Premium (HSM-backed)                 │  │
│  │ • Secrets, Keys, Certificates                        │  │
│  │ • Soft Delete: 7-90 days retention                   │  │
│  │ • Purge Protection: Enabled                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ RBAC Authorization                                   │  │
│  │ • Key Vault Administrator (auto-assigned)            │  │
│  │ • Key Vault Secrets User                             │  │
│  │ • Key Vault Crypto Officer                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Network Security (via Network ACLs)                  │  │
│  │ • Public Access: Configurable                        │  │
│  │ • Network ACLs: Deny by default                      │  │
│  │ • Allowed IPs/Subnets: Configurable                  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                      │
                      │ (Use modules/PrivateEndpoint)
                      ▼
          ┌───────────────────────┐
          │   Private Endpoint    │
          │   (Separate Module)   │
          └───────────────────────┘
```

---

## ✨ Features

### Access Management

- 🔑 **Azure native RBAC** - Role-based access control (recommended)
- 🔑 **Automatic assignment** - Admin role for current user (optional)
- 🔑 **Tenant ID auto-detection** - Automatically uses current tenant if not specified

### Data Protection

- 🛡️ **Soft Delete** - 7-90 days retention (recovery possible)
- 🛡️ **Purge Protection** - Prevents permanent deletion (IRREVERSIBLE!)
- 🛡️ **Disk Encryption** - Support for Azure Disk Encryption
- 🛡️ **VM Deployment** - Support for VM deployments
- 🛡️ **ARM Templates** - Support for Azure Resource Manager templates

### Network Security

- 🔒 **Network ACLs** - IP/Subnet filtering with whitelist
- 🔒 **Bypass Azure Services** - Allow trusted Azure services
- 🔒 **Public Access Control** - Enable/disable public network access

### Observability

- 📊 **Diagnostic Settings** - Logs and metrics to Log Analytics
- 📊 **Audit Events** - All secret/key access recorded
- 📊 **Policy Evaluation** - Azure Policy compliance logs

---

## 🚀 Usage

### Basic Usage

```hcl
module "keyvault" {
  source = "./modules/KeyVault"

  name                = "kv-myapp-prod-weu-01"
  location            = "westeurope"
  resource_group_name = "rg-security-prod-weu-01"

  sku_name    = "standard"
  enable_rbac = true

  tags = {
    Environment = "Production"
    CostCenter  = "Security"
  }
}
```

### Production Configuration

```hcl
module "keyvault" {
  source = "./modules/KeyVault"

  name                = "kv-banking-prod-weu-01"
  location            = "westeurope"
  resource_group_name = "rg-security-prod-weu-01"

  # Premium SKU for HSM
  sku_name    = "premium"
  enable_rbac = true

  # Maximum security
  soft_delete_retention_days = 90
  purge_protection_enabled   = true  # ⚠️ IRREVERSIBLE!

  # Encryption enablement
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = false

  # Disable public access (use Private Endpoint)
  public_network_access_enabled = false

  # Strict Network ACLs
  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
    subnet_ids     = []
  }

  # Telemetry
  enable_telemetry = true
  telemetry_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    log_categories             = ["AuditEvent", "AzurePolicyEvaluationDetails"]
    metric_categories          = ["AllMetrics"]
  }

  tags = {
    Environment = "Production"
    Compliance  = "PCI-DSS"
    Criticality = "Critical"
  }
}
```

---

## 📝 Variables

### Required Variables

| Name                  | Type     | Description                           |
| --------------------- | -------- | ------------------------------------- |
| `name`                | `string` | Key Vault name (3-24 characters)      |
| `location`            | `string` | Azure region                          |
| `resource_group_name` | `string` | Existing Resource Group name          |

### Optional Variables

| Name                              | Type     | Default     | Description                              |
| --------------------------------- | -------- | ----------- | ---------------------------------------- |
| `tenant_id`                       | `string` | `null`      | Azure AD Tenant ID (auto-detected)       |
| `sku_name`                        | `string` | `"premium"` | SKU: `standard` or `premium` (HSM)       |
| `enable_rbac`                     | `bool`   | `true`      | Enable RBAC (recommended)                |
| `assign_rbac_to_current_user`     | `bool`   | `true`      | Auto-assign Admin role                   |
| `enabled_for_disk_encryption`     | `bool`   | `false`     | Support Azure Disk Encryption            |
| `enabled_for_deployment`          | `bool`   | `false`     | Support VM deployments                   |
| `enabled_for_template_deployment` | `bool`   | `false`     | Support ARM templates                    |
| `soft_delete_retention_days`      | `number` | `90`        | Soft delete retention (7-90 days)        |
| `purge_protection_enabled`        | `bool`   | `true`      | Purge protection (IRREVERSIBLE!)         |
| `public_network_access_enabled`   | `bool`   | `false`     | Public access                            |
| `network_acls`                    | `object` | `null`      | Network firewall configuration           |
| `tags`                            | `map`    | `{}`        | Custom tags                              |
| `enable_telemetry`                | `bool`   | `false`     | Enable diagnostic settings               |
| `telemetry_settings`              | `object` | `null`      | Logs and metrics configuration           |

### Network ACLs Structure

```hcl
network_acls = {
  default_action = "Deny"              # "Allow" or "Deny"
  bypass         = "AzureServices"     # "AzureServices" or "None"
  ip_rules       = ["1.2.3.4/32"]      # List of public IPs
  subnet_ids     = [subnet.id]         # List of subnet IDs
}
```

---

## 📤 Outputs

| Name                          | Description                                       |
| ----------------------------- | ------------------------------------------------- |
| `id`                          | Key Vault resource ID                             |
| `uri`                         | Key Vault URI (`https://kv-xxx.vault.azure.net/`) |
| `name`                        | Key Vault name                                    |
| `location`                    | Azure region                                      |
| `resource_group_name`         | Resource group name                               |
| `tenant_id`                   | Tenant ID                                         |
| `sku_name`                    | SKU name                                          |
| `rbac_enabled`                | Whether RBAC is enabled                           |
| `purge_protection_enabled`    | Whether purge protection is enabled               |
| `soft_delete_retention_days`  | Soft delete retention days                        |
| `public_network_access_enabled` | Whether public access is enabled               |
| `tags`                        | Applied tags                                      |

---

## 🔗 Private Endpoint Integration

### Why Separate Modules?

1. **Principle DRY** - Single source of truth for Private Endpoint logic
2. **Flexibility** - Create Key Vault with or without PE
3. **Consistency** - All PEs (KeyVault, Storage, SQL) use same module
4. **Maintainability** - Update PE logic in one place

### Complete Example with Private Endpoint

```hcl
# 1. Create Private DNS Zone (once per subscription/VNet)
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.rg_network.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-keyvault-to-vnet"
  resource_group_name   = module.rg_network.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.vnet.id
}

# 2. Create Key Vault (this module)
module "keyvault" {
  source = "./modules/KeyVault"

  name                          = "kv-myapp-prod-weu-01"
  location                      = "westeurope"
  resource_group_name           = "rg-app-prod-weu-01"
  sku_name                      = "premium"
  enable_rbac                   = true
  public_network_access_enabled = false

  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = []
    subnet_ids     = []
  }

  tags = { Environment = "Production" }
}

# 3. Create Private Endpoint (separate module)
module "private_endpoint_keyvault" {
  source = "./modules/PrivateEndpoint"

  location            = "westeurope"
  resource_group_name = "rg-app-prod-weu-01"
  subnet_id           = module.subnets.id["snet-private-endpoints"]

  private_endpoints = [
    {
      name               = "pep-kv-myapp-prod-weu-01"
      resource_id        = module.keyvault.id
      subresource_names  = ["vault"]
      private_ip_address = "10.0.10.10"  # Optional static IP

      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
      }
    }
  ]

  tags = { Environment = "Production" }

  depends_on = [
    module.keyvault,
    azurerm_private_dns_zone_virtual_network_link.keyvault
  ]
}

# 4. Use outputs
output "keyvault_uri" {
  value = module.keyvault.uri
}

output "keyvault_private_ip" {
  value = module.private_endpoint_keyvault.private_ip_addresses["pep-kv-myapp-prod-weu-01"]
}
```

---

## 🔒 Security Best Practices

### Production Checklist

- [ ] **Premium SKU** for HSM-backed keys
- [ ] **RBAC enabled** (`enable_rbac = true`)
- [ ] **Public access disabled** (`public_network_access_enabled = false`)
- [ ] **Network ACLs** with `default_action = "Deny"`
- [ ] **Private Endpoint** configured (separate module)
- [ ] **Private DNS Zone** linked to VNet
- [ ] **Purge protection enabled** (`purge_protection_enabled = true`)
- [ ] **Maximum soft delete retention** (`soft_delete_retention_days = 90`)
- [ ] **Telemetry enabled** to Log Analytics
- [ ] **Tags** include Compliance, Criticality, Owner

### Naming Convention

```
kv-<application>-<environment>-<region>-<instance>

Examples:
- kv-banking-prod-weu-01
- kv-webapp-staging-eus-01
- kv-shared-prod-weu-01
```

**Constraints**:
- 3-24 characters
- Alphanumerics and hyphens only
- Globally unique (Azure-wide)

---

## 📄 Changelog

### Version 2.0.0 (Breaking Change)
- ❌ **Removed**: Private Endpoint integration (use `modules/PrivateEndpoint`)
- ✅ **Added**: Better validation for name, tenant_id
- ✅ **Added**: Auto-detection of tenant_id
- ✅ **Improved**: Cleaner outputs
- ✅ **Improved**: Documentation

### Version 1.0.0
- Initial release with integrated Private Endpoint

---

## 📚 Related Modules

- [`modules/PrivateEndpoint`](../PrivateEndpoint/README.md) - For Private Endpoint creation
- [`modules/KeyVault-Key`](../KeyVault-Key/README.md) - For Key creation and rotation

---

**⭐ If this module helps you, feel free to share it!**
