#################################################################################
# Module PrivateEndpoint - Point de Terminaison Privé Azure (Private Endpoint)
#################################################################################
# Description: Ce module crée et gère des Private Endpoints Azure pour connecter
#              de manière sécurisée des services Azure PaaS (Storage, Key Vault,
#              SQL, etc.) à un réseau virtuel privé. Les Private Endpoints
#              permettent d'accéder aux services via une adresse IP privée,
#              éliminant ainsi l'exposition sur Internet public.
#################################################################################

###############################################################
# Ressource Time Static
###############################################################
# Capture le timestamp exact de la première application Terraform
# Utilisée pour ajouter le tag 'CreatedOn' au Private Endpoint
resource "time_static" "time" {}

###############################################################
# Ressource: Private Endpoint Azure
###############################################################
# Description: Crée un ou plusieurs Private Endpoints pour connecter
#              des services Azure PaaS à un sous-réseau privé
# Attributs principaux:
#   - name: Nom du Private Endpoint (fourni via variable)
#   - location: Région Azure (fourni via variable)
#   - resource_group_name: Groupe de ressources (fourni via variable)
#   - subnet_id: ID du sous-réseau où créer le Private Endpoint
#
# Structure attendue pour chaque endpoint:
# {
#   name                         = "pep-keyvault-prod-weu-01"
#   resource_id                  = "/subscriptions/.../resourceGroups/.../providers/..."
#   subresource_names            = ["vault"]  # ou ["blob"], ["sqlServer"], etc.
#   is_manual_connection         = false
#   private_dns_zone_group       = {...} (optionnel)
#   private_ip_address           = "10.0.1.5" (optionnel)
#   custom_network_interface_name = "nic-pep-xxx" (optionnel)
# }
resource "azurerm_private_endpoint" "this" {
  for_each = { for ep in var.private_endpoints : ep.name => ep }

  # Nom du Private Endpoint
  name = each.value.name

  # Région Azure où créer le Private Endpoint
  location = var.location

  # Groupe de ressources contenant le Private Endpoint
  resource_group_name = var.resource_group_name

  # ID du sous-réseau où déployer le Private Endpoint
  # Note: Le sous-réseau doit avoir 'private_endpoint_network_policies' = "Disabled"
  subnet_id = var.subnet_id

  # Nom personnalisé de l'interface réseau (optionnel)
  custom_network_interface_name = lookup(each.value, "custom_network_interface_name", null)

  ###############################################################
  # Bloc: Private Service Connection
  ###############################################################
  # Description: Définit la connexion au service Azure cible
  # Attributs:
  #   - name: Nom de la connexion
  #   - private_connection_resource_id: ID de la ressource Azure cible
  #   - subresource_names: Sous-ressources à exposer (ex: "vault", "blob")
  #   - is_manual_connection: true si approbation manuelle requise
  #   - request_message: Message pour connexion manuelle (optionnel)
  private_service_connection {
    # Nom de la connexion de service privé
    name = "psc-${each.value.name}"

    # ID de la ressource Azure à connecter (Key Vault, Storage, SQL, etc.)
    private_connection_resource_id = each.value.resource_id

    # Sous-ressources à exposer via le Private Endpoint
    # Exemples par type de ressource:
    #   - Key Vault: ["vault"]
    #   - Storage Account: ["blob"], ["file"], ["queue"], ["table"], ["web"], ["dfs"]
    #   - SQL Server: ["sqlServer"]
    #   - Cosmos DB: ["Sql"], ["MongoDB"], ["Cassandra"], ["Gremlin"], ["Table"]
    #   - Azure Container Registry: ["registry"]
    #   - Event Hub: ["namespace"]
    #   - Service Bus: ["namespace"]
    #   - App Configuration: ["configurationStores"]
    subresource_names = each.value.subresource_names

    # Connexion manuelle (nécessite approbation du propriétaire de la ressource)
    # true = Connexion en attente d'approbation
    # false = Connexion automatique (même abonnement/tenant)
    is_manual_connection = lookup(each.value, "is_manual_connection", false)

    # Message de demande pour les connexions manuelles
    request_message = lookup(each.value, "request_message", null)
  }

  ###############################################################
  # Bloc Dynamique: Configuration IP Statique
  ###############################################################
  # Description: Optionnellement configure une adresse IP privée statique
  #              pour le Private Endpoint au lieu d'une allocation dynamique
  # Conditions d'utilisation: private_ip_address ne doit pas être null
  # Note: L'IP doit être dans la plage du sous-réseau
  dynamic "ip_configuration" {
    for_each = lookup(each.value, "private_ip_address", null) != null ? [1] : []
    content {
      # Nom de la configuration IP
      name = "ipc-${each.value.name}"

      # Adresse IP privée statique
      private_ip_address = each.value.private_ip_address

      # Nom de la sous-ressource (doit correspondre à subresource_names)
      subresource_name = each.value.subresource_names[0]

      # Nom du membre (généralement "default")
      member_name = lookup(each.value, "member_name", "default")
    }
  }

  ###############################################################
  # Bloc Dynamique: Groupe de Zone DNS Privée
  ###############################################################
  # Description: Optionnellement lie le Private Endpoint à une zone DNS privée
  #              pour la résolution de nom automatique
  # Conditions d'utilisation: private_dns_zone_group ne doit pas être null
  # Note: Requiert une zone DNS privée existante liée au VNet
  dynamic "private_dns_zone_group" {
    for_each = lookup(each.value, "private_dns_zone_group", null) != null ? [each.value.private_dns_zone_group] : []

    content {
      # Nom du groupe de zone DNS
      name = lookup(private_dns_zone_group.value, "name", "default")

      # IDs des zones DNS privées à associer
      # Exemples de zones par service:
      #   - Key Vault: privatelink.vaultcore.azure.net
      #   - Blob Storage: privatelink.blob.core.windows.net
      #   - SQL Server: privatelink.database.windows.net
      #   - Cosmos DB: privatelink.documents.azure.com
      private_dns_zone_ids = private_dns_zone_group.value.private_dns_zone_ids
    }
  }

  ###############################################################
  # Tags
  ###############################################################
  # Fusionne les tags fournis par l'utilisateur avec un tag système 'CreatedOn'
  # et des tags spécifiques au Private Endpoint
  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      CreatedOn       = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
      TargetResource  = each.value.resource_id
      SubresourceType = join(",", each.value.subresource_names)
    }
  )
}

###############################################################
# Data Source: Récupération des IPs après création
###############################################################
# Description: Permet de récupérer les informations détaillées
#              des Private Endpoints créés, notamment les IPs privées
# Note: Utilisé pour les outputs et l'intégration avec d'autres modules
data "azurerm_private_endpoint_connection" "this" {
  for_each = azurerm_private_endpoint.this

  name                = each.value.name
  resource_group_name = var.resource_group_name

  depends_on = [azurerm_private_endpoint.this]
}
