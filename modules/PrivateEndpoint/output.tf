###############################################################
# OUTPUT: private_endpoints
# Description: Map complète des Private Endpoints créés
# Format: { "endpoint-name" = azurerm_private_endpoint.this["endpoint-name"], ... }
# Usage: Accès à tous les attributs des Private Endpoints
###############################################################
output "private_endpoints" {
  description = "Ressources Private Endpoint complètes par nom"
  value       = azurerm_private_endpoint.this
}

###############################################################
# OUTPUT: ids
# Description: Map des IDs de Private Endpoints
# Format: { "endpoint-name" = "/subscriptions/.../privateEndpoints/endpoint-name", ... }
# Usage: Référencer les Private Endpoints dans d'autres ressources
###############################################################
output "ids" {
  description = "IDs des Private Endpoints par nom"
  value       = { for k, v in azurerm_private_endpoint.this : k => v.id }
}

###############################################################
# OUTPUT: names
# Description: Map des noms de Private Endpoints
# Format: { "endpoint-name" = "endpoint-name", ... }
# Usage: Référence pour la documentation ou le logging
###############################################################
output "names" {
  description = "Noms des Private Endpoints"
  value       = { for k, v in azurerm_private_endpoint.this : k => v.name }
}

###############################################################
# OUTPUT: private_ip_addresses
# Description: Map des adresses IP privées attribuées
# Format: { "endpoint-name" = "10.0.1.5", ... }
# Usage: Configuration DNS, pare-feu, ou documentation réseau
###############################################################
output "private_ip_addresses" {
  description = "Adresses IP privées des Private Endpoints"
  value = {
    for k, v in azurerm_private_endpoint.this :
    k => try(v.private_service_connection[0].private_ip_address, null)
  }
}

###############################################################
# OUTPUT: network_interface_ids
# Description: Map des IDs d'interfaces réseau des Private Endpoints
# Format: { "endpoint-name" = "/subscriptions/.../networkInterfaces/nic-xxx", ... }
# Usage: Référence pour la configuration réseau avancée
###############################################################
output "network_interface_ids" {
  description = "IDs des interfaces réseau des Private Endpoints"
  value       = { for k, v in azurerm_private_endpoint.this : k => v.network_interface[0].id }
}

###############################################################
# OUTPUT: network_interface_names
# Description: Map des noms d'interfaces réseau
# Format: { "endpoint-name" = "nic-pep-xxx", ... }
# Usage: Référence pour le diagnostic ou la documentation
###############################################################
output "network_interface_names" {
  description = "Noms des interfaces réseau des Private Endpoints"
  value       = { for k, v in azurerm_private_endpoint.this : k => v.network_interface[0].name }
}

###############################################################
# OUTPUT: connection_status
# Description: Map des états de connexion des Private Endpoints
# Format: { "endpoint-name" = "Approved", ... }
# Values possibles: "Pending", "Approved", "Rejected", "Disconnected"
# Usage: Vérification de l'état des connexions
###############################################################
output "connection_status" {
  description = "États de connexion des Private Endpoints"
  value = {
    for k, v in data.azurerm_private_endpoint_connection.this :
    k => v.private_service_connection[0].status
  }
}

###############################################################
# OUTPUT: custom_dns_configs
# Description: Configurations DNS personnalisées pour chaque endpoint
# Format: { "endpoint-name" = { fqdn = "...", ip_addresses = [...] }, ... }
# Usage: Configuration DNS manuelle si pas de zone DNS privée
###############################################################
output "custom_dns_configs" {
  description = "Configurations DNS personnalisées des Private Endpoints"
  value = {
    for k, v in azurerm_private_endpoint.this :
    k => {
      fqdn         = try(v.custom_dns_configs[0].fqdn, null)
      ip_addresses = try(v.custom_dns_configs[0].ip_addresses, [])
    }
  }
}

###############################################################
# OUTPUT: private_dns_zone_configs
# Description: Configurations des zones DNS privées
# Format: { "endpoint-name" = { zone_name = "...", record_sets = [...] }, ... }
# Usage: Vérification de l'intégration DNS
###############################################################
output "private_dns_zone_configs" {
  description = "Configurations des zones DNS privées des Private Endpoints"
  value = {
    for k, v in azurerm_private_endpoint.this :
    k => [
      for dns in try(v.private_dns_zone_configs, []) : {
        name        = dns.name
        record_sets = dns.record_sets
      }
    ]
  }
}

###############################################################
# OUTPUT: endpoint_details
# Description: Informations détaillées sur chaque Private Endpoint
# Structure: Map avec toutes les infos essentielles par endpoint
# Usage: Documentation, monitoring, audit
###############################################################
output "endpoint_details" {
  description = "Informations détaillées sur chaque Private Endpoint"
  value = {
    for k, v in azurerm_private_endpoint.this :
    k => {
      id                    = v.id
      name                  = v.name
      location              = v.location
      resource_group_name   = v.resource_group_name
      subnet_id             = v.subnet_id
      private_ip_address    = try(v.private_service_connection[0].private_ip_address, null)
      target_resource_id    = v.private_service_connection[0].private_connection_resource_id
      subresource_names     = v.private_service_connection[0].subresource_names
      connection_status     = try(data.azurerm_private_endpoint_connection.this[k].private_service_connection[0].status, "Unknown")
      is_manual_connection  = v.private_service_connection[0].is_manual_connection
      network_interface_id  = v.network_interface[0].id
      tags                  = v.tags
    }
  }
}

###############################################################
# OUTPUT: subnet_id
# Description: ID du sous-réseau utilisé pour les Private Endpoints
# Usage: Référence pour la documentation ou d'autres modules
###############################################################
output "subnet_id" {
  description = "ID du sous-réseau des Private Endpoints"
  value       = var.subnet_id
}

###############################################################
# OUTPUT: location
# Description: Région Azure des Private Endpoints
# Usage: Cohérence de déploiement
###############################################################
output "location" {
  description = "Région Azure des Private Endpoints"
  value       = var.location
}

###############################################################
# OUTPUT: resource_group_name
# Description: Nom du groupe de ressources des Private Endpoints
# Usage: Référence pour d'autres ressources
###############################################################
output "resource_group_name" {
  description = "Nom du groupe de ressources"
  value       = var.resource_group_name
}

###############################################################
# OUTPUT: endpoints_by_service_type
# Description: Private Endpoints groupés par type de sous-ressource
# Format: { "vault" = ["pep-kv-1"], "blob" = ["pep-st-1", "pep-st-2"], ... }
# Usage: Analyse et reporting par type de service
###############################################################
output "endpoints_by_service_type" {
  description = "Private Endpoints groupés par type de sous-ressource"
  value = {
    for subresource in distinct(flatten([
      for ep in var.private_endpoints : ep.subresource_names
    ])) :
    subresource => [
      for ep in var.private_endpoints :
      ep.name if contains(ep.subresource_names, subresource)
    ]
  }
}
