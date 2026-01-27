# Azure Private Endpoint Terraform Module

Ce module Terraform crée et gère des Private Endpoints Azure pour connecter de manière sécurisée des services Azure PaaS à un réseau virtuel privé.

## Fonctionnalités

- Création de multiples Private Endpoints en une seule invocation
- Support des adresses IP statiques
- Intégration avec les zones DNS privées
- Support des connexions manuelles (cross-tenant/subscription)
- Validation robuste des inputs
- Tags automatiques avec timestamp de création
- Outputs détaillés pour l'intégration avec d'autres modules

## Usage

### Exemple Basique - Key Vault

```hcl
module "private_endpoints" {
  source = "./modules/PrivateEndpoint"

  location            = "westeurope"
  resource_group_name = module.rg.name
  subnet_id           = module.subnets.id["snet-private-endpoints"]

  private_endpoints = [
    {
      name              = "pep-kv-prod-weu-01"
      resource_id       = azurerm_key_vault.main.id
      subresource_names = ["vault"]
      
      private_dns_zone_group = {
        name                 = "default"
        private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
      }
    }
  ]

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}
```

### Exemple Avancé - Multiples Services

```hcl
module "private_endpoints" {
  source = "./modules/PrivateEndpoint"

  location            = var.location
  resource_group_name = module.rg_network.name
  subnet_id           = module.subnets.id["snet-private-endpoints"]

  private_endpoints = [
    # Key Vault
    {
      name               = "pep-kv-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id        = azurerm_key_vault.main.id
      subresource_names  = ["vault"]
      private_ip_address = "10.0.10.10"
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
      }
      
      tags = {
        service = "key-vault"
      }
    },
    
    # Storage Account - Blob
    {
      name              = "pep-st-blob-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_storage_account.main.id
      subresource_names = ["blob"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
      }
      
      tags = {
        service = "storage-blob"
      }
    },
    
    # Storage Account - File
    {
      name              = "pep-st-file-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_storage_account.main.id
      subresource_names = ["file"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
      }
      
      tags = {
        service = "storage-file"
      }
    },
    
    # SQL Server
    {
      name              = "pep-sql-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_mssql_server.main.id
      subresource_names = ["sqlServer"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
      }
      
      tags = {
        service = "sql-server"
      }
    },
    
    # Cosmos DB
    {
      name              = "pep-cosmos-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_cosmosdb_account.main.id
      subresource_names = ["Sql"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.cosmos.id]
      }
      
      tags = {
        service = "cosmos-db"
      }
    }
  ]

  tags = {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
  }
}
```

### Exemple avec Connexion Manuelle (Cross-Subscription)

```hcl
module "private_endpoints_cross_sub" {
  source = "./modules/PrivateEndpoint"

  location            = "westeurope"
  resource_group_name = module.rg.name
  subnet_id           = module.subnets.id["snet-private-endpoints"]

  private_endpoints = [
    {
      name                 = "pep-external-service-prod-weu-01"
      resource_id          = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-external/providers/Microsoft.Storage/storageAccounts/stexternal"
      subresource_names    = ["blob"]
      is_manual_connection = true
      request_message      = "Demande de connexion Private Endpoint depuis le projet ${var.project}"
    }
  ]

  tags = {
    environment = "production"
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

| Name                  | Description                                          | Type           | Default | Required |
| --------------------- | ---------------------------------------------------- | -------------- | ------- | :------: |
| location              | Région Azure pour les Private Endpoints              | `string`       | n/a     |   yes    |
| resource_group_name   | Nom du groupe de ressources                          | `string`       | n/a     |   yes    |
| subnet_id             | ID du sous-réseau pour les Private Endpoints         | `string`       | n/a     |   yes    |
| private_endpoints     | Liste des configurations de Private Endpoints        | `list(object)` | n/a     |   yes    |
| tags                  | Tags communs pour tous les Private Endpoints         | `map(string)`  | `{}`    |    no    |
| enable_telemetry      | Activer les paramètres de diagnostic                 | `bool`         | `false` |    no    |
| telemetry_settings    | Configuration des paramètres de diagnostic           | `object`       | `null`  |    no    |

### Structure de `private_endpoints`

```hcl
private_endpoints = [
  {
    name                          = string           # Requis: Nom du Private Endpoint
    resource_id                   = string           # Requis: ID de la ressource Azure cible
    subresource_names             = list(string)     # Requis: Sous-ressources à exposer
    is_manual_connection          = bool             # Optionnel: Connexion manuelle (default: false)
    request_message               = string           # Optionnel: Message pour connexion manuelle
    private_ip_address            = string           # Optionnel: IP statique
    member_name                   = string           # Optionnel: Nom du membre (default: "default")
    custom_network_interface_name = string           # Optionnel: Nom personnalisé de la NIC
    private_dns_zone_group = {                       # Optionnel: Configuration DNS
      name                 = string                  # Optionnel: Nom du groupe (default: "default")
      private_dns_zone_ids = list(string)            # Requis: IDs des zones DNS
    }
    tags = map(string)                               # Optionnel: Tags spécifiques
  }
]
```

## Outputs

| Name                      | Description                                                |
| ------------------------- | ---------------------------------------------------------- |
| private_endpoints         | Ressources Private Endpoint complètes par nom              |
| ids                       | IDs des Private Endpoints par nom                          |
| names                     | Noms des Private Endpoints                                 |
| private_ip_addresses      | Adresses IP privées des Private Endpoints                  |
| network_interface_ids     | IDs des interfaces réseau                                  |
| network_interface_names   | Noms des interfaces réseau                                 |
| connection_status         | États de connexion (Pending, Approved, Rejected, etc.)     |
| custom_dns_configs        | Configurations DNS personnalisées                          |
| private_dns_zone_configs  | Configurations des zones DNS privées                       |
| endpoint_details          | Informations détaillées sur chaque endpoint                |
| subnet_id                 | ID du sous-réseau utilisé                                  |
| location                  | Région Azure                                               |
| resource_group_name       | Nom du groupe de ressources                                |
| endpoints_by_service_type | Endpoints groupés par type de sous-ressource               |

## Subresource Names par Service

| Service Azure           | Subresource Names                                          |
| ----------------------- | ---------------------------------------------------------- |
| Key Vault               | `vault`                                                    |
| Storage Account         | `blob`, `file`, `queue`, `table`, `web`, `dfs`            |
| SQL Server              | `sqlServer`                                                |
| SQL Managed Instance    | `managedInstance`                                          |
| Cosmos DB               | `Sql`, `MongoDB`, `Cassandra`, `Gremlin`, `Table`         |
| Azure Container Registry| `registry`                                                 |
| Event Hub               | `namespace`                                                |
| Service Bus             | `namespace`                                                |
| App Configuration       | `configurationStores`                                      |
| Synapse                 | `Sql`, `SqlOnDemand`, `Dev`                               |
| Azure Monitor           | `prometheusMetrics`                                        |
| Cognitive Services      | `account`                                                  |
| Azure Search            | `searchService`                                            |
| SignalR                 | `signalr`                                                  |
| Web Apps / Function Apps| `sites`                                                    |
| Redis Cache             | `redisCache`                                               |
| PostgreSQL              | `postgresqlServer`                                         |
| MySQL                   | `mysqlServer`                                              |
| MariaDB                 | `mariadbServer`                                            |

## Zones DNS Privées par Service

| Service                 | Zone DNS Privée                                            |
| ----------------------- | ---------------------------------------------------------- |
| Key Vault               | `privatelink.vaultcore.azure.net`                          |
| Storage Blob            | `privatelink.blob.core.windows.net`                        |
| Storage File            | `privatelink.file.core.windows.net`                        |
| Storage Queue           | `privatelink.queue.core.windows.net`                       |
| Storage Table           | `privatelink.table.core.windows.net`                       |
| Storage Web             | `privatelink.web.core.windows.net`                         |
| Storage DFS             | `privatelink.dfs.core.windows.net`                         |
| SQL Server              | `privatelink.database.windows.net`                         |
| Cosmos DB (SQL)         | `privatelink.documents.azure.com`                          |
| Cosmos DB (MongoDB)     | `privatelink.mongo.cosmos.azure.com`                       |
| ACR                     | `privatelink.azurecr.io`                                   |
| Event Hub               | `privatelink.servicebus.windows.net`                       |
| Service Bus             | `privatelink.servicebus.windows.net`                       |
| App Configuration       | `privatelink.azconfig.io`                                  |
| Azure Search            | `privatelink.search.windows.net`                           |
| Web Apps                | `privatelink.azurewebsites.net`                            |
| Redis Cache             | `privatelink.redis.cache.windows.net`                      |
| PostgreSQL              | `privatelink.postgres.database.azure.com`                  |
| MySQL                   | `privatelink.mysql.database.azure.com`                     |

## Prérequis Subnet

Le sous-réseau utilisé pour les Private Endpoints doit avoir la configuration suivante:

```hcl
module "subnets" {
  source = "./modules/Subnet"
  
  # ...
  
  subnets = [
    {
      name                               = "snet-private-endpoints"
      address_prefixes                   = ["10.0.10.0/24"]
      private_endpoint_network_policies  = "Disabled"  # Important!
    }
  ]
}
```

## Exemple Complet avec Zones DNS Privées

```hcl
###############################################################
# Zones DNS Privées
###############################################################
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.rg_network.name
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = module.rg_network.name
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg_network.name
}

###############################################################
# Liens VNet pour les Zones DNS
###############################################################
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-keyvault-to-vnet"
  resource_group_name   = module.rg_network.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = module.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-blob-to-vnet"
  resource_group_name   = module.rg_network.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = module.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "link-sql-to-vnet"
  resource_group_name   = module.rg_network.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = module.vnet.id
  registration_enabled  = false
}

###############################################################
# Private Endpoints
###############################################################
module "private_endpoints" {
  source = "./modules/PrivateEndpoint"

  location            = var.location
  resource_group_name = module.rg_network.name
  subnet_id           = module.subnets.id["snet-private-endpoints"]

  private_endpoints = [
    {
      name              = "pep-kv-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_key_vault.main.id
      subresource_names = ["vault"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
      }
    },
    {
      name              = "pep-st-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_storage_account.main.id
      subresource_names = ["blob"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
      }
    },
    {
      name              = "pep-sql-${var.project}-${var.environment}-${var.region_code}-01"
      resource_id       = azurerm_mssql_server.main.id
      subresource_names = ["sqlServer"]
      
      private_dns_zone_group = {
        private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
      }
    }
  ]

  tags = local.common_tags

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.keyvault,
    azurerm_private_dns_zone_virtual_network_link.blob,
    azurerm_private_dns_zone_virtual_network_link.sql
  ]
}
```

## Best Practices

1. **Subnet Dédié** : Utilisez un subnet dédié aux Private Endpoints avec `private_endpoint_network_policies = "Disabled"`

2. **Zones DNS Privées** : Toujours configurer les zones DNS privées pour une résolution de nom automatique

3. **Liens VNet** : Assurez-vous que les zones DNS sont liées à tous les VNets qui doivent résoudre les noms

4. **Naming Convention** : Utilisez une convention cohérente (ex: `pep-{service}-{project}-{env}-{region}-{index}`)

5. **IP Statiques** : Utilisez des IPs statiques pour les services critiques afin d'éviter les changements lors des mises à jour

6. **Monitoring** : Surveillez l'état des connexions via `connection_status` output

## Troubleshooting

### État "Pending"

Si l'état de connexion reste "Pending":
- Vérifiez que `is_manual_connection = false` pour les ressources du même tenant
- Pour les connexions cross-tenant, approuvez manuellement dans le portail Azure

### Résolution DNS Échouée

Si la résolution DNS ne fonctionne pas:
- Vérifiez que la zone DNS privée est créée
- Vérifiez que le lien VNet est configuré
- Vérifiez que `private_dns_zone_group` est configuré dans le Private Endpoint

### Impossible de Créer le Private Endpoint

Si la création échoue:
- Vérifiez que `private_endpoint_network_policies = "Disabled"` sur le subnet
- Vérifiez les permissions sur la ressource cible
- Vérifiez que le service supporte les Private Endpoints

## Resources Created

- `azurerm_private_endpoint` - Les Private Endpoints
- `time_static` - Timestamp pour le tag CreatedOn

## License

MIT
