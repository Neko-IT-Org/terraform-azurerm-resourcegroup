# 🏗️ Module AVL (Azure Virtual Landing Zone)

Module Terraform orchestrateur pour déployer une **Landing Zone Azure complète** avec architecture **Hub-and-Spoke** et firewall **Palo Alto VM-Series**.

---

## 📋 Table des Matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Fonctionnalités](#-fonctionnalités)
- [Prérequis](#-prérequis)
- [Utilisation](#-utilisation)
- [Variables](#-variables)
- [Outputs](#-outputs)
- [Exemples](#-exemples)

---

## 🎯 Vue d'ensemble

Ce module déploie une **Landing Zone Azure production-ready** incluant:

- **Hub VNet** avec 3 subnets (Management, Untrust, Trust)
- **Spoke VNets** pour Applications et Données
- **NSGs** avec règles de sécurité personnalisables
- **Route Tables** pour forcer le trafic via le firewall
- **VNet Peerings** bidirectionnels automatiques
- **Palo Alto VM-Series** (optionnel)
- **Télémétrie** vers Log Analytics

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  HUB VNET (10.0.0.0/16)                     │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐                │
│  │ Management │  │ Untrust  │  │  Trust   │                │
│  │ 10.0.1.0/24│  │10.0.2.0/24│ │10.0.3.0/24│               │
│  │    NSG     │  │   NSG    │  │   NSG    │                │
│  └─────┬──────┘  └────┬─────┘  └────┬─────┘                │
│        │              │              │                       │
│        └──────┬───────┴──────┬───────┘                      │
│               │              │                               │
│      ┌────────▼──────────────▼────────┐                    │
│      │  Palo Alto VM-Series Firewall  │                    │
│      │  • 3 NICs (Mgmt/Untrust/Trust) │                    │
│      │  • Bootstrap Support            │                    │
│      │  • HA Ready                     │                    │
│      └─────────────────────────────────┘                    │
└──────────────────────┬──────────────────────────────────────┘
                       │ VNet Peering (Bidirectionnel)
         ┌─────────────┼─────────────┐
         │             │             │
  ┌──────▼───────┐  ┌─▼──────────┐  │
  │ SPOKE APP    │  │ SPOKE DATA │  │
  │ 10.1.0.0/16  │  │10.2.0.0/16 │  │
  │ • Web Subnet │  │ • DB Subnet│  │
  │ • App Subnet │  │            │  │
  │ • UDR → FW   │  │ • UDR → FW │  │
  └──────────────┘  └────────────┘  │
```

### Flux de Trafic

- **North-South**: Internet ↔ Firewall (Untrust) ↔ Spokes
- **East-West**: Spoke ↔ Firewall (Trust) ↔ Spoke
- **Management**: Subnet dédié avec NSG strict

---

## ✨ Fonctionnalités

### Infrastructure

- ✅ **Hub-and-Spoke complet** - Architecture centralisée
- ✅ **Multi-Spoke** - App, Data, Shared Services
- ✅ **Modulaire** - Activation/désactivation par feature flags
- ✅ **Multi-environnement** - Dev, Staging, Production

### Sécurité

- 🔒 **NSGs granulaires** - Règles personnalisables par subnet
- 🔒 **UDRs automatiques** - Force le trafic via le firewall
- 🔒 **Palo Alto VM-Series** - Firewall de niveau entreprise
- 🔒 **Locks conditionnels** - Protection automatique en prod
- 🔒 **SSH Key Auth** - Aucune authentification par mot de passe

### Observabilité

- 📊 **Log Analytics** - Intégration complète
- 📊 **Diagnostic Settings** - Sur toutes les ressources
- 📊 **Tagging automatique** - CreatedOn, Project, Environment
- 📊 **Outputs détaillés** - Résumé complet de l'infrastructure

---

## 📦 Prérequis

### Outils

| Outil      | Version | Description                |
| ---------- | ------- | -------------------------- |
| Terraform  | ≥ 1.5.0 | Infrastructure provisioning|
| Azure CLI  | ≥ 2.50  | Authentification Azure     |

### Azure

- Subscription active
- Permissions Contributor
- Service Principal (pour CI/CD)
- Acceptation des termes Marketplace Palo Alto

```bash
az vm image terms accept \
  --publisher paloaltonetworks \
  --offer vmseries-flex \
  --plan byol
```

---

## 🚀 Utilisation

### Utilisation Basique

```hcl
module "landing_zone" {
  source = "./modules/LandingZone"

  # Configuration de base
  project_name = "neko"
  environment  = "prod"
  location     = "westeurope"

  # Configuration réseau
  hub_vnet_address_space        = "10.0.0.0/16"
  spoke_app_vnet_address_space  = "10.1.0.0/16"
  spoke_data_vnet_address_space = "10.2.0.0/16"

  # Firewall (optionnel)
  deploy_firewall            = true
  palo_alto_admin_ssh_key    = var.ssh_public_key
  firewall_trust_private_ip  = "10.0.3.4"

  # Télémétrie
  enable_telemetry           = true
  log_analytics_workspace_id = var.workspace_id

  # Tags
  tags = {
    CostCenter = "IT-Infra"
    Owner      = "Platform-Team"
  }
}
```

### Avec Shared Services

```hcl
module "landing_zone_full" {
  source = "./modules/LandingZone"

  project_name = "mycompany"
  environment  = "prod"
  location     = "westeurope"

  # Activer le Spoke Shared Services
  deploy_shared_services = true
  spoke_shared_vnet_address_space = "10.3.0.0/16"

  # Autres configurations...
  deploy_firewall = true
  enable_telemetry = true

  tags = {
    BusinessUnit = "Infrastructure"
    Compliance   = "ISO27001"
  }
}
```

---

## 📝 Variables

### Variables Essentielles

| Nom                           | Type     | Default        | Description                    |
| ----------------------------- | -------- | -------------- | ------------------------------ |
| `project_name`                | `string` | `"neko"`       | Nom du projet                  |
| `environment`                 | `string` | **REQUIRED**   | dev/staging/prod               |
| `location`                    | `string` | `"westeurope"` | Région Azure                   |
| `hub_vnet_address_space`      | `string` | `"10.0.0.0/16"`| CIDR du Hub                    |
| `spoke_app_vnet_address_space`| `string` | `"10.1.0.0/16"`| CIDR Spoke App                 |
| `spoke_data_vnet_address_space`|`string` | `"10.2.0.0/16"`| CIDR Spoke Data                |

### Variables Firewall

| Nom                              | Type     | Default           | Description               |
| -------------------------------- | -------- | ----------------- | ------------------------- |
| `deploy_firewall`                | `bool`   | `false`           | Déployer Palo Alto        |
| `palo_alto_vm_size`              | `string` | `"Standard_D3_v2"`| Taille VM                 |
| `palo_alto_sku`                  | `string` | `"byol"`          | SKU (byol/bundle1/bundle2)|
| `palo_alto_admin_ssh_key`        | `string` | `null`            | Clé SSH publique          |
| `firewall_trust_private_ip`      | `string` | `"10.0.3.4"`      | IP Trust (next hop)       |
| `bootstrap_storage_account_name` | `string` | `null`            | Storage pour bootstrap    |

### Variables Télémétrie

| Nom                           | Type     | Default | Description               |
| ----------------------------- | -------- | ------- | ------------------------- |
| `enable_telemetry`            | `bool`   | `true`  | Activer diagnostic        |
| `log_analytics_workspace_id`  | `string` | `null`  | ID Workspace Log Analytics|

### Feature Flags

| Nom                      | Type   | Default | Description                  |
| ------------------------ | ------ | ------- | ---------------------------- |
| `deploy_shared_services` | `bool` | `false` | Déployer Spoke Shared        |
| `deploy_vpn_gateway`     | `bool` | `false` | Déployer VPN Gateway         |
| `enable_ddos_protection` | `bool` | `false` | Activer DDoS Protection      |

---

## 📤 Outputs

### Outputs Principaux

```hcl
# Resource Groups
output "resource_groups" { ... }

# Virtual Networks
output "vnets" { ... }

# Subnets par VNet
output "subnets" { ... }

# NSGs
output "nsgs" { ... }

# Route Tables
output "route_tables" { ... }

# Peerings
output "peerings" { ... }

# Firewall (si déployé)
output "firewall" { ... }

# Résumé complet
output "landing_zone_summary" { ... }

# Prochaines étapes
output "next_steps" { ... }
```

---

## 📚 Exemples

### Exemple 1: Landing Zone Dev Simple

```hcl
module "lz_dev" {
  source = "./modules/LandingZone"

  project_name = "acme"
  environment  = "dev"
  location     = "westeurope"

  # Pas de firewall en dev
  deploy_firewall = false

  # Télémétrie désactivée en dev
  enable_telemetry = false

  tags = {
    Environment = "Development"
    Owner       = "DevTeam"
  }
}
```

### Exemple 2: Landing Zone Production Complète

```hcl
module "lz_prod" {
  source = "./modules/LandingZone"

  project_name = "acme"
  environment  = "prod"
  location     = "westeurope"

  # Déploiement complet
  deploy_firewall        = true
  deploy_shared_services = true

  # Firewall configuration
  palo_alto_vm_size       = "Standard_D4_v2"
  palo_alto_admin_ssh_key = file("~/.ssh/palo_key.pub")
  
  # Bootstrap
  bootstrap_storage_account_name = "stpalofwbootstrapprod"
  bootstrap_storage_access_key   = data.azurerm_key_vault_secret.bootstrap_key.value
  bootstrap_share_name           = "bootstrap"

  # Télémétrie
  enable_telemetry           = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Sécurité
  enable_ddos_protection = true

  # Subnets personnalisés
  spoke_app_subnets = {
    web = {
      address_prefix = "10.1.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      nsg_rules = [
        {
          name                       = "Allow-HTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Allow HTTPS from Internet"
        }
      ]
    }
    app = {
      address_prefix = "10.1.2.0/24"
      service_endpoints = ["Microsoft.Sql"]
      nsg_rules = [
        {
          name                       = "Allow-From-Web"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "8080"
          source_address_prefix      = "10.1.1.0/24"
          destination_address_prefix = "*"
          description                = "Allow from web tier"
        }
      ]
    }
  }

  tags = {
    Environment  = "Production"
    CostCenter   = "IT-Infrastructure"
    Compliance   = "ISO27001"
    Criticality  = "High"
  }
}
```

### Exemple 3: Multi-Région avec DR

```hcl
# Région Principale
module "lz_primary" {
  source = "./modules/LandingZone"

  project_name = "acme"
  environment  = "prod"
  location     = "westeurope"

  hub_vnet_address_space        = "10.0.0.0/16"
  spoke_app_vnet_address_space  = "10.1.0.0/16"
  spoke_data_vnet_address_space = "10.2.0.0/16"

  deploy_firewall = true
  # ... autres configs
}

# Région DR
module "lz_dr" {
  source = "./modules/LandingZone"

  project_name = "acme"
  environment  = "prod"
  location     = "northeurope"

  hub_vnet_address_space        = "10.10.0.0/16"
  spoke_app_vnet_address_space  = "10.11.0.0/16"
  spoke_data_vnet_address_space = "10.12.0.0/16"

  deploy_firewall = true
  # ... autres configs
}

# Peering Global entre régions
module "global_peering" {
  source = "./modules/VNetPeering"

  peerings = [
    {
      name                        = "peer-weu-to-neu"
      source_virtual_network_name = module.lz_primary.vnets.hub.name
      source_resource_group_name  = module.lz_primary.resource_groups.hub.name
      source_virtual_network_id   = module.lz_primary.vnets.hub.id
      remote_virtual_network_id   = module.lz_dr.vnets.hub.id
      remote_virtual_network_name = module.lz_dr.vnets.hub.name
      remote_resource_group_name  = module.lz_dr.resource_groups.hub.name

      allow_forwarded_traffic = true
      create_reverse_peering  = true
    }
  ]
}
```

---

## 🔧 Personnalisation

### NSG Rules Personnalisées

Les règles NSG peuvent être complètement personnalisées via les variables `spoke_app_subnets` et `spoke_data_subnets`:

```hcl
spoke_app_subnets = {
  frontend = {
    address_prefix = "10.1.1.0/24"
    nsg_rules = [
      # Règle HTTP
      {
        name                       = "Allow-HTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Allow HTTP"
      },
      # Règle HTTPS
      {
        name                       = "Allow-HTTPS"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        description                = "Allow HTTPS"
      },
      # Deny All
      {
        name                       = "Deny-All"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
        description                = "Deny all other traffic"
      }
    ]
  }
}
```

---

## 📊 Coûts Estimés

### Région: West Europe (estimations mensuelles)

| Ressource                    | Quantité | Coût/Mois (USD) |
| ---------------------------- | -------- | --------------- |
| Palo Alto VM (Standard_D3_v2)| 1        | ~$180           |
| Public IPs (Standard)        | 2        | ~$7             |
| VNet Peering (1TB)           | 2        | ~$20            |
| Log Analytics (5GB)          | 1        | ~$10            |
| **TOTAL**                    |          | **~$217**       |

*Sans Palo Alto: ~$37/mois*

---

## ✅ Best Practices

1. **Utiliser des workspaces** - Séparer les environnements
2. **Activer la télémétrie** - Toujours en production
3. **Locks automatiques** - Protection en prod (déjà implémenté)
4. **Bootstrap le firewall** - Configuration automatisée
5. **Nommage cohérent** - Via project_name et environment

---

## 🐛 Troubleshooting

### Le firewall ne démarre pas

```bash
# Vérifier les logs de diagnostic
az vm boot-diagnostics get-boot-log \
  --name vm-neko-paloalto-prod-weu-01 \
  --resource-group rg-neko-hub-prod-weu-01
```

### Peering en état "Initiated"

Les peerings sont créés automatiquement dans les deux sens via `create_reverse_peering = true`. Si un peering reste en "Initiated", vérifier les permissions.

### Impossible de SSH vers le firewall

Vérifier que votre IP est autorisée dans les NSG rules du subnet Management.

---

## 📄 Licence

MIT License

## 👥 Auteurs

**Neko-IT-Org**

---

**⭐ Si ce module vous aide, donnez-lui une star!**
