#################################################################################
# Module Subnet - Sous-réseau Azure (Subnet)
#################################################################################
# Description: Ce module crée et gère des sous-réseaux Azure (Subnets) au sein
#              d'un réseau virtuel existant. Il associe également les NSG
#              (Network Security Groups) et Route Tables à chaque sous-réseau.
#              Les sous-réseaux sont des divisions logiques du VNet pour segmenter
#              le réseau et appliquer des stratégies de sécurité.
#################################################################################

###############################################################
# Ressource: Sous-réseaux Azure
###############################################################
# Description: Crée un ou plusieurs sous-réseaux dans un VNet existant
# Cette ressource utilise for_each pour créer plusieurs subnets
# Chaque subnet est identifié par son nom unique
#
# Structure attendue pour chaque subnet:
# {
#   name                             = "subnet-name"
#   address_prefixes                 = ["10.0.1.0/24"]
#   service_endpoints                = ["Microsoft.Storage", "Microsoft.Sql"] (optionnel)
#   default_outbound_access_enabled  = true/false (optionnel)
#   private_endpoint_network_policies = "Enabled"/"Disabled" (optionnel)
#   ip_address_pool                  = {...} (optionnel)
#   delegations                      = [...] (optionnel)
#   nsg_id                           = "resource-id" (optionnel)
#   route_table_id                   = "resource-id" (optionnel)
# }
resource "azurerm_subnet" "this" {
  for_each                          = { for s in var.subnets : s.name => s }
  
  # Nom du sous-réseau
  name                              = each.value.name
  
  # Groupe de ressources contenant le VNet
  resource_group_name               = var.resource_group_name
  
  # Nom du réseau virtuel parent
  virtual_network_name              = var.virtual_network_name
  
  # Plages d'adresses IP du subnet (notation CIDR)
  # Exemple: ["10.0.1.0/24"]
  address_prefixes                  = each.value.address_prefixes
  
  # Endpoints de service Microsoft (optionnel)
  # Exemples: "Microsoft.Storage", "Microsoft.Sql", "Microsoft.EventHub"
  # Permet l'accès direct aux services Azure sans passer par internet
  service_endpoints                 = lookup(each.value, "service_endpoints", null)
  
  # Active/désactive l'accès sortant par défaut pour les VMs (optionnel)
  # true = accès sortant par défaut activé
  # false = accès sortant par défaut désactivé (nécessite une route)
  default_outbound_access_enabled   = lookup(each.value, "default_outbound_access_enabled", null)
  
  # Contrôle les stratégies réseau des endpoints privés (optionnel)
  # "Enabled" ou "Disabled"
  private_endpoint_network_policies = lookup(each.value, "private_endpoint_network_policies", null)

  ###############################################################
  # Bloc Dynamique: Pool d'Adresses IP
  ###############################################################
  # Description: Optionnellement configure un pool d'adresses IP privées
  #              pour ce sous-réseau
  # Conditions d'utilisation: ip_address_pool ne doit pas être null
  dynamic "ip_address_pool" {
    for_each = lookup(each.value, "ip_address_pool", null) != null ? [each.value.ip_address_pool] : []
    content {
      # ID du pool d'adresses IP
      id                     = ip_address_pool.value.id
      
      # Nombre d'adresses IP à utiliser du pool
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
    }
  }

  ###############################################################
  # Bloc Dynamique: Délégations de Sous-réseau
  ###############################################################
  # Description: Optionnellement délègue des permissions à des services Azure
  #              pour créer des ressources gérées dans ce sous-réseau
  # Utilisation: Certains services Azure (ex: SQL Managed Instances, App Services)
  #              nécessitent une délégation pour déployer des ressources
  #
  # Structure attendue:
  # delegations = [
  #   {
  #     name = "delegation-name"
  #     service_delegation = {
  #       name    = "Microsoft.DBforPostgreSQL/serversv2"
  #       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
  #     }
  #   }
  # ]
  dynamic "delegation" {
    for_each = lookup(each.value, "delegations", [])
    content {
      # Nom identifiant la délégation
      name = delegation.value.name

      # Configuration de la délégation de service
      service_delegation {
        # Nom du service Azure (ex: "Microsoft.DBforPostgreSQL/serversv2")
        name    = delegation.value.service_delegation.name
        
        # Actions autorisées pour le service
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

###############################################################
# Ressource: Association NSG - Subnet
###############################################################
# Description: Associe optionnellement un NSG (Network Security Group) à chaque subnet
# Cette ressource crée une association entre le subnet et un NSG existant
# pour appliquer les règles de sécurité réseau
#
# Conditions: Un NSG n'est associé que si:
#   1. La clé "nsg_id" existe dans la configuration du subnet
#   2. La valeur de nsg_id n'est pas null
#
# Utilisation: Permet de contrôler le trafic entrant/sortant du subnet
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    for s in var.subnets : s.name => s
    if contains(keys(s), "nsg_id") && s.nsg_id != null
  }
  
  # ID du subnet auquel associer le NSG
  subnet_id                 = azurerm_subnet.this[each.key].id
  
  # ID du NSG à associer
  network_security_group_id = each.value.nsg_id
}

###############################################################
# Ressource: Association Route Table - Subnet
###############################################################
# Description: Associe optionnellement une Route Table à chaque subnet
# Cette ressource crée une association entre le subnet et une Route Table existante
# pour diriger le trafic selon les routes définies
#
# Conditions: Une Route Table n'est associée que si:
#   1. La clé "route_table_id" existe dans la configuration du subnet
#   2. La valeur de route_table_id n'est pas null
#
# Utilisation: Permet de définir les routes de trafic personnalisées pour le subnet
#              Exemple: rediriger le trafic vers une appliance virtuelle, VPN, etc.
resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    for s in var.subnets : s.name => s
    if contains(keys(s), "route_table_id") && s.route_table_id != null
  }
  
  # ID du subnet auquel associer la Route Table
  subnet_id      = azurerm_subnet.this[each.key].id
  
  # ID de la Route Table à associer
  route_table_id = each.value.route_table_id
}
