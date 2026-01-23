#################################################################################
# Module RouteTable - Table de Routage Azure (Route Table)
#################################################################################
# Description: Ce module crée et gère une table de routage Azure (Route Table).
#              Une route table définit comment le trafic réseau est dirigé dans
#              le réseau virtuel. Elle peut rediriger le trafic vers des appliances
#              virtuelles, des passerelles VPN, des points de terminaison d'Internet, etc.
#################################################################################

###############################################################
# Ressource Time Static
###############################################################
# Capture le timestamp exact de la première application Terraform
# Utilisée pour ajouter le tag 'CreatedOn' à la table de routage
resource "time_static" "time" {}

###############################################################
# Ressource: Table de Routage Azure
###############################################################
# Description: Crée une table de routage Azure avec des routes configurables
#              et un contrôle optionnel de la propagation des routes BGP
# Attributs principaux:
#   - name: Nom de la table de routage (fourni via variable)
#   - location: Région Azure (fourni via variable)
#   - resource_group_name: Groupe de ressources (fourni via variable)
#   - bgp_route_propagation_enabled: Active/désactive la propagation BGP
resource "azurerm_route_table" "this" {
  # Nom de la table de routage
  name                          = var.name
  
  # Région Azure où créer la table de routage
  location                      = var.location
  
  # Groupe de ressources contenant la table de routage
  resource_group_name           = var.resource_group_name
  
  # Active/désactive la propagation des routes BGP (Border Gateway Protocol)
  # true = Les routes apprises via BGP sont propagées automatiquement
  # false = Les routes BGP ne sont pas propagées
  # Utile pour les connexions ExpressRoute ou VPN site-à-site
  bgp_route_propagation_enabled = var.bgp_route_propagation_enabled

  ###############################################################
  # Bloc Dynamique: Routes
  ###############################################################
  # Description: Crée dynamiquement N routes basées sur la variable input
  # Chaque route définit où diriger le trafic pour une plage d'adresses IP donnée
  #
  # Structure attendue pour chaque route:
  # {
  #   name                   = "route-name"
  #   address_prefix         = "10.0.0.0/8"
  #   next_hop_type          = "VirtualNetworkGateway" | "VnetLocal" | "Internet" | "VirtualAppliance" | "None"
  #   next_hop_in_ip_address = "10.0.1.4" (optionnel, requis pour "VirtualAppliance")
  # }
  #
  # Types de Next Hop:
  #   - VirtualNetworkGateway: Redirection vers une passerelle VPN ou ExpressRoute
  #   - VnetLocal: Trafic local au VNet (ne quitte pas le VNet)
  #   - Internet: Redirection vers Internet (via la passerelle Internet par défaut)
  #   - VirtualAppliance: Redirection vers une appliance virtuelle (ex: Firewall)
  #   - None: Le trafic est ignoré (blackhole routing)
  dynamic "route" {
    for_each = var.route
    content {
      # Nom identifiant la route
      name                   = route.value.name
      
      # Plage d'adresses IP de destination (notation CIDR)
      # Exemple: "10.1.0.0/16", "0.0.0.0/0" (défaut route)
      address_prefix         = route.value.address_prefix
      
      # Type de saut suivant (où diriger le trafic)
      next_hop_type          = route.value.next_hop_type
      
      # Adresse IP du saut suivant (si next_hop_type = "VirtualAppliance")
      # Exemple: "10.0.1.4" pour une appliance virtuelle
      # Null pour les autres types de saut suivant
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
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
      # 'CreatedOn' tag contient la date/heure de création
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}
