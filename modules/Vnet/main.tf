#################################################################################
# Module Vnet - Réseau Virtuel Azure (Virtual Network)
#################################################################################
# Description: Ce module crée et gère un réseau virtuel Azure (VNet). Un VNet
#              est le bloc de base de construction pour les ressources réseau privées
#              dans Azure. Il fournit l'isolation réseau et permet la communication
#              entre les ressources Azure et entre le réseau sur site et Azure.
#################################################################################

###############################################################
# Ressource Time Static
###############################################################
# Capture le timestamp exact de la première application Terraform
# Utilisée pour ajouter le tag 'CreatedOn' au VNet
resource "time_static" "time" {}

###############################################################
# Ressource: Réseau Virtuel Azure (VNet)
###############################################################
# Description: Crée un réseau virtuel Azure avec configuration optionnelle
#              pour DDoS protection et IP address pools
# Attributs principaux:
#   - name: Nom du VNet (fourni via variable)
#   - address_space: Plages d'adresses IP (ex: ["10.0.0.0/8", "172.16.0.0/12"])
#   - location: Région Azure
#   - resource_group_name: Groupe de ressources
#   - dns_servers: Serveurs DNS optionnels
resource "azurerm_virtual_network" "this" {
  # Nom du réseau virtuel
  name = var.name

  # Espace d'adressage du VNet (plages CIDR)
  # Exemple: ["10.0.0.0/16", "10.1.0.0/16"]
  # Défini à null si la variable address_space est vide
  address_space = var.address_space != [] ? var.address_space : null

  # Région Azure où créer le VNet (ex: "eastus", "westeurope")
  location = var.location

  # Groupe de ressources contenant le VNet
  resource_group_name = var.resource_group_name

  # Serveurs DNS personnalisés pour la résolution de noms
  # Défini à null si la variable dns_servers est vide
  # Exemple: ["8.8.8.8", "8.8.4.4"] pour Google DNS
  dns_servers = var.dns_servers != [] ? var.dns_servers : null

  ###############################################################
  # Bloc Dynamique: Protection DDoS
  ###############################################################
  # Description: Optionnellement active la protection DDoS Standard sur le VNet
  # La protection DDoS Standard fournit une protection améliorée contre les attaques DDoS
  # Conditions d'activation:
  #   1. enable_ddos_protection doit être true
  #   2. ddos_protection_plan_id doit être fourni (non null)
  # 
  # Note: Le plan DDoS doit être créé en dehors de ce module
  dynamic "ddos_protection_plan" {
    for_each = var.enable_ddos_protection && var.ddos_protection_plan_id != null ? [var.ddos_protection_plan_id] : []
    content {
      # Active la protection DDoS
      enable = var.enable_ddos_protection
      
      # ID du plan DDoS Protection existant
      id     = ddos_protection_plan.value
    }
  }

  ###############################################################
  # Bloc Dynamique: IP Address Pool
  ###############################################################
  # Description: Optionnellement configure un pool d'adresses IP privées pour le VNet
  # Utilisation: Permet de définir des pools d'IP privées personnalisées
  # Conditions d'utilisation:
  #   - ip_address_pool ne doit pas être null
  #
  # Structure attendue:
  #   {
  #     id                     = "resource-id-of-ip-pool"
  #     number_of_ip_addresses = 100
  #   }
  dynamic "ip_address_pool" {
    for_each = var.ip_address_pool == null ? [] : [var.ip_address_pool]
    content {
      # ID du pool d'adresses IP
      id                     = ip_address_pool.value.id
      
      # Nombre d'adresses IP à utiliser du pool
      number_of_ip_addresses = ip_address_pool.value.number_of_ip_addresses
    }
  }

  ###############################################################
  # Tags
  ###############################################################
  # Fusionne les tags fournis par l'utilisateur avec un tag système 'CreatedOn'
  # CreatedOn contient la date/heure de création formatée en DD-MM-YYYY hh:mm
  # Un décalage d'une heure est appliqué au timestamp
  tags = merge(
    var.tags,
    {
      # 'CreatedOn' tag contient le timestamp de création
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}
