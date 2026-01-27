###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Région Azure où déployer les Private Endpoints
# Example: "westeurope", "eastus", "francecentral"
###############################################################
variable "location" {
  description = "Région Azure pour les Private Endpoints"
  type        = string
}

###############################################################
# VARIABLE: resource_group_name
# Type: string (required)
# Description: Nom du groupe de ressources contenant les Private Endpoints
###############################################################
variable "resource_group_name" {
  description = "Nom du groupe de ressources"
  type        = string
}

###############################################################
# VARIABLE: subnet_id
# Type: string (required)
# Description: ID du sous-réseau où déployer les Private Endpoints
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Network/virtualNetworks/<vnet>/subnets/<subnet>
# Note: Le sous-réseau doit avoir private_endpoint_network_policies = "Disabled"
###############################################################
variable "subnet_id" {
  description = "ID du sous-réseau pour les Private Endpoints"
  type        = string

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.subnet_id))
    error_message = "L'ID du sous-réseau doit être un ID de ressource Azure valide."
  }
}

###############################################################
# VARIABLE: private_endpoints
# Type: list(object) (required)
# Description: Liste des configurations de Private Endpoints à créer
# Structure:
#   - name (required): Nom du Private Endpoint
#   - resource_id (required): ID de la ressource Azure cible
#   - subresource_names (required): Liste des sous-ressources à exposer
#   - is_manual_connection (optional): Connexion manuelle (default: false)
#   - request_message (optional): Message pour connexion manuelle
#   - private_ip_address (optional): IP privée statique
#   - member_name (optional): Nom du membre (default: "default")
#   - custom_network_interface_name (optional): Nom personnalisé de la NIC
#   - private_dns_zone_group (optional): Configuration DNS privée
#   - tags (optional): Tags spécifiques à ce Private Endpoint
#
# Subresource Names par type de service:
#   Key Vault:           ["vault"]
#   Storage Blob:        ["blob"]
#   Storage File:        ["file"]
#   Storage Queue:       ["queue"]
#   Storage Table:       ["table"]
#   Storage Web:         ["web"]
#   Storage DFS:         ["dfs"]
#   SQL Server:          ["sqlServer"]
#   SQL On-Demand:       ["sqlOnDemand"]
#   Cosmos DB SQL:       ["Sql"]
#   Cosmos DB MongoDB:   ["MongoDB"]
#   ACR:                 ["registry"]
#   Event Hub:           ["namespace"]
#   Service Bus:         ["namespace"]
#   App Configuration:   ["configurationStores"]
#   Synapse:             ["Sql"], ["SqlOnDemand"], ["Dev"]
#   Azure Monitor:       ["prometheusMetrics"]
#   Cognitive Services:  ["account"]
#   Search:              ["searchService"]
#   SignalR:             ["signalr"]
#   Web Apps:            ["sites"]
#   Function Apps:       ["sites"]
#   Redis Cache:         ["redisCache"]
###############################################################
variable "private_endpoints" {
  description = "Liste des configurations de Private Endpoints"
  type = list(object({
    # Nom du Private Endpoint (required)
    name = string

    # ID de la ressource Azure cible (required)
    # Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/<provider>/<type>/<name>
    resource_id = string

    # Sous-ressources à exposer via le Private Endpoint (required)
    # Voir la documentation ci-dessus pour les valeurs par type de service
    subresource_names = list(string)

    # Connexion manuelle nécessitant approbation (optional)
    # true = En attente d'approbation du propriétaire
    # false = Auto-approuvé (même tenant/subscription)
    is_manual_connection = optional(bool, false)

    # Message de demande pour connexion manuelle (optional)
    request_message = optional(string)

    # Adresse IP privée statique (optional)
    # Si null, Azure attribue automatiquement une IP
    private_ip_address = optional(string)

    # Nom du membre pour la configuration IP (optional)
    # Généralement "default"
    member_name = optional(string, "default")

    # Nom personnalisé de l'interface réseau (optional)
    custom_network_interface_name = optional(string)

    # Configuration de la zone DNS privée (optional)
    private_dns_zone_group = optional(object({
      name                 = optional(string, "default")
      private_dns_zone_ids = list(string)
    }))

    # Tags spécifiques à ce Private Endpoint (optional)
    tags = optional(map(string), {})
  }))

  ###############################################################
  # VALIDATION: subresource_names non vide
  # Description: Vérifie que chaque endpoint a au moins une sous-ressource
  ###############################################################
  validation {
    condition = alltrue([
      for ep in var.private_endpoints :
      length(ep.subresource_names) > 0
    ])
    error_message = "Chaque Private Endpoint doit avoir au moins une sous-ressource définie dans subresource_names."
  }

  ###############################################################
  # VALIDATION: resource_id format
  # Description: Vérifie que resource_id est un ID de ressource Azure valide
  ###############################################################
  validation {
    condition = alltrue([
      for ep in var.private_endpoints :
      can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/", ep.resource_id))
    ])
    error_message = "resource_id doit être un ID de ressource Azure valide (format: /subscriptions/.../resourceGroups/.../providers/...)."
  }

  ###############################################################
  # VALIDATION: private_ip_address format
  # Description: Si fourni, vérifie que l'IP est au format valide
  ###############################################################
  validation {
    condition = alltrue([
      for ep in var.private_endpoints :
      ep.private_ip_address == null || can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", ep.private_ip_address))
    ])
    error_message = "private_ip_address doit être une adresse IPv4 valide (format: x.x.x.x)."
  }

  ###############################################################
  # VALIDATION: request_message pour connexion manuelle
  # Description: Vérifie que request_message est fourni si is_manual_connection = true
  ###############################################################
  validation {
    condition = alltrue([
      for ep in var.private_endpoints :
      ep.is_manual_connection == false || ep.is_manual_connection == null || (ep.request_message != null && ep.request_message != "")
    ])
    error_message = "request_message est requis lorsque is_manual_connection est true."
  }
}

###############################################################
# VARIABLE: tags
# Type: map(string) (optional)
# Default: {} (empty map)
# Description: Tags communs à appliquer à tous les Private Endpoints
# Note: Seront fusionnés avec les tags spécifiques de chaque endpoint
###############################################################
variable "tags" {
  description = "Tags communs pour tous les Private Endpoints"
  type        = map(string)
  default     = {}
}

###############################################################
# VARIABLE: enable_telemetry
# Type: bool (optional)
# Default: false
# Description: Activer les paramètres de diagnostic pour la télémétrie
# Note: Les Private Endpoints ont des capacités de diagnostic limitées
###############################################################
variable "enable_telemetry" {
  description = "Activer les paramètres de diagnostic pour la télémétrie"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: telemetry_settings
# Type: object (optional, nullable)
# Default: null
# Description: Configuration des paramètres de diagnostic
# Structure:
#   - log_analytics_workspace_id: ID du workspace Log Analytics
#   - storage_account_id: ID du compte de stockage pour archivage
#   - event_hub_authorization_rule_id: ID de la règle Event Hub
#   - event_hub_name: Nom de l'Event Hub
#   - metric_categories: Catégories de métriques à activer
###############################################################
variable "telemetry_settings" {
  description = "Configuration des paramètres de diagnostic pour la télémétrie"
  type = object({
    log_analytics_workspace_id      = optional(string)
    storage_account_id              = optional(string)
    event_hub_authorization_rule_id = optional(string)
    event_hub_name                  = optional(string)
    metric_categories               = optional(list(string), ["AllMetrics"])
  })
  default  = null
  nullable = true

  validation {
    condition = var.telemetry_settings == null || (
      var.telemetry_settings.log_analytics_workspace_id != null ||
      var.telemetry_settings.storage_account_id != null ||
      var.telemetry_settings.event_hub_authorization_rule_id != null
    )
    error_message = "Si telemetry_settings est fourni, au moins une destination doit être spécifiée."
  }
}
