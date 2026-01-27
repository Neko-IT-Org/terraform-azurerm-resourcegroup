###############################################################
# MODULE: AVL Landing Zone - Outputs
# Description: Sorties du module Landing Zone
###############################################################

###############################################################
# RESOURCE GROUPS
###############################################################
output "resource_groups" {
  description = "Tous les Resource Groups créés"
  value = {
    hub = {
      id       = module.rg_hub.id
      name     = module.rg_hub.name
      location = module.rg_hub.location
    }
    spoke_app = {
      id       = module.rg_spoke_app.id
      name     = module.rg_spoke_app.name
      location = module.rg_spoke_app.location
    }
    spoke_data = {
      id       = module.rg_spoke_data.id
      name     = module.rg_spoke_data.name
      location = module.rg_spoke_data.location
    }
    spoke_shared = var.deploy_shared_services ? {
      id       = module.rg_spoke_shared[0].id
      name     = module.rg_spoke_shared[0].name
      location = module.rg_spoke_shared[0].location
    } : null
  }
}

###############################################################
# VIRTUAL NETWORKS
###############################################################
output "vnets" {
  description = "Tous les VNets créés"
  value = {
    hub = {
      id                  = module.vnet_hub.id
      name                = module.vnet_hub.name
      address_space       = var.hub_vnet_address_space
      resource_group_name = module.vnet_hub.resource_group_name
    }
    spoke_app = {
      id                  = module.vnet_spoke_app.id
      name                = module.vnet_spoke_app.name
      address_space       = var.spoke_app_vnet_address_space
      resource_group_name = module.vnet_spoke_app.resource_group_name
    }
    spoke_data = {
      id                  = module.vnet_spoke_data.id
      name                = module.vnet_spoke_data.name
      address_space       = var.spoke_data_vnet_address_space
      resource_group_name = module.vnet_spoke_data.resource_group_name
    }
    spoke_shared = var.deploy_shared_services ? {
      id                  = module.vnet_spoke_shared[0].id
      name                = module.vnet_spoke_shared[0].name
      address_space       = var.spoke_shared_vnet_address_space
      resource_group_name = module.vnet_spoke_shared[0].resource_group_name
    } : null
  }
}

###############################################################
# SUBNETS
###############################################################
output "subnets" {
  description = "Tous les subnets créés par VNet"
  value = {
    hub = {
      management = {
        id               = module.subnets_hub.id["snet-management"]
        name             = module.subnets_hub.name["snet-management"]
        address_prefixes = module.subnets_hub.address_prefixes["snet-management"]
      }
      untrust = {
        id               = module.subnets_hub.id["snet-untrust"]
        name             = module.subnets_hub.name["snet-untrust"]
        address_prefixes = module.subnets_hub.address_prefixes["snet-untrust"]
      }
      trust = {
        id               = module.subnets_hub.id["snet-trust"]
        name             = module.subnets_hub.name["snet-trust"]
        address_prefixes = module.subnets_hub.address_prefixes["snet-trust"]
      }
    }
    spoke_app = {
      for subnet_key in keys(var.spoke_app_subnets) :
      subnet_key => {
        id               = module.subnets_spoke_app.id["snet-${subnet_key}"]
        name             = module.subnets_spoke_app.name["snet-${subnet_key}"]
        address_prefixes = module.subnets_spoke_app.address_prefixes["snet-${subnet_key}"]
      }
    }
    spoke_data = {
      for subnet_key in keys(var.spoke_data_subnets) :
      subnet_key => {
        id               = module.subnets_spoke_data.id["snet-${subnet_key}"]
        name             = module.subnets_spoke_data.name["snet-${subnet_key}"]
        address_prefixes = module.subnets_spoke_data.address_prefixes["snet-${subnet_key}"]
      }
    }
  }
}

###############################################################
# NETWORK SECURITY GROUPS
###############################################################
output "nsgs" {
  description = "Tous les NSGs créés"
  value = {
    hub = {
      management = {
        id   = module.nsg_hub_management.id
        name = module.nsg_hub_management.name
      }
      untrust = {
        id   = module.nsg_hub_untrust.id
        name = module.nsg_hub_untrust.name
      }
      trust = {
        id   = module.nsg_hub_trust.id
        name = module.nsg_hub_trust.name
      }
    }
    spoke_app = {
      for subnet_key in keys(var.spoke_app_subnets) :
      subnet_key => {
        id   = module.nsg_spoke_app[subnet_key].id
        name = module.nsg_spoke_app[subnet_key].name
      }
    }
    spoke_data = {
      for subnet_key in keys(var.spoke_data_subnets) :
      subnet_key => {
        id   = module.nsg_spoke_data[subnet_key].id
        name = module.nsg_spoke_data[subnet_key].name
      }
    }
  }
}

###############################################################
# ROUTE TABLES
###############################################################
output "route_tables" {
  description = "Toutes les route tables créées"
  value = {
    spoke_to_firewall = {
      id     = module.rt_spoke_to_firewall.route_table_id
      name   = module.rt_spoke_to_firewall.route_table_name
      routes = module.rt_spoke_to_firewall.route_table_route
    }
  }
}

###############################################################
# PEERINGS
###############################################################
output "peerings" {
  description = "Tous les peerings créés"
  value = {
    hub_to_spoke_app = {
      forward_ids    = module.peering_hub_to_spoke_app.peering_ids
      reverse_ids    = module.peering_hub_to_spoke_app.reverse_peering_ids
      states         = module.peering_hub_to_spoke_app.peering_states
      reverse_states = module.peering_hub_to_spoke_app.reverse_peering_states
    }
    hub_to_spoke_data = {
      forward_ids    = module.peering_hub_to_spoke_data.peering_ids
      reverse_ids    = module.peering_hub_to_spoke_data.reverse_peering_ids
      states         = module.peering_hub_to_spoke_data.peering_states
      reverse_states = module.peering_hub_to_spoke_data.reverse_peering_states
    }
    hub_to_spoke_shared = var.deploy_shared_services ? {
      forward_ids    = module.peering_hub_to_spoke_shared[0].peering_ids
      reverse_ids    = module.peering_hub_to_spoke_shared[0].reverse_peering_ids
      states         = module.peering_hub_to_spoke_shared[0].peering_states
      reverse_states = module.peering_hub_to_spoke_shared[0].reverse_peering_states
    } : null
  }
}

###############################################################
# PALO ALTO FIREWALL
###############################################################
output "firewall" {
  description = "Informations sur le firewall Palo Alto (si déployé)"
  value = var.deploy_firewall ? {
    vm_name            = module.palo_alto_firewall[0].vm_name
    vm_id              = module.palo_alto_firewall[0].vm_id
    mgmt_public_ip     = module.palo_alto_firewall[0].mgmt_public_ip
    untrust_public_ip  = module.palo_alto_firewall[0].untrust_public_ip
    mgmt_private_ip    = var.firewall_mgmt_private_ip
    untrust_private_ip = var.firewall_untrust_private_ip
    trust_private_ip   = var.firewall_trust_private_ip
  } : null
  sensitive = false
}

###############################################################
# LANDING ZONE SUMMARY
###############################################################
output "landing_zone_summary" {
  description = "Résumé de l'architecture Landing Zone déployée"
  value = {
    project_name = var.project_name
    environment  = var.environment
    location     = var.location

    topology = {
      type   = "Hub-and-Spoke"
      hub    = module.vnet_hub.name
      spokes = local.deployed_spokes
    }

    network_summary = {
      hub_address_space        = var.hub_vnet_address_space
      spoke_app_address_space  = var.spoke_app_vnet_address_space
      spoke_data_address_space = var.spoke_data_vnet_address_space
      total_vnets              = 2 + (var.deploy_shared_services ? 1 : 0)
    }

    security = {
      firewall_deployed = var.deploy_firewall
      firewall_type     = var.deploy_firewall ? "Palo Alto VM-Series" : null
      ddos_protection   = var.enable_ddos_protection
      telemetry_enabled = var.enable_telemetry
    }

    routing = {
      default_route_via_firewall = var.deploy_firewall
      firewall_trust_ip          = var.firewall_trust_private_ip
      bgp_propagation_disabled   = true
    }
  }
}

###############################################################
# NEXT STEPS
###############################################################
locals {
  log_analytics_status = var.log_analytics_workspace_id != null ? "Activé" : "Non configuré"

  next_steps_with_firewall = <<-EOT
  
  ✅ Landing Zone déployée avec succès!
  
  📋 Prochaines étapes:
  
  1️⃣ CONFIGURATION DU FIREWALL
     • SSH: ssh ${var.palo_alto_admin_username}@<firewall-mgmt-public-ip> -i <votre-cle-ssh>
     • Web UI: https://<firewall-mgmt-public-ip>
     • Configurer les zones (Trust, Untrust, Management)
     • Créer les politiques de sécurité
  
  2️⃣ DÉPLOIEMENT DES WORKLOADS
     • Spoke App: Déployer vos VMs/Apps dans ${var.spoke_app_vnet_address_space}
     • Spoke Data: Déployer vos bases de données dans ${var.spoke_data_vnet_address_space}
  
  3️⃣ TESTS DE CONNECTIVITÉ
     • Test Spoke-to-Spoke via Firewall
     • Test Internet Outbound via Firewall
     • Vérifier les logs du firewall
  
  4️⃣ MONITORING
     • Vérifier Log Analytics: ${local.log_analytics_status}
     • Configurer les alertes Azure Monitor
     • Configurer les dashboards
  
  📊 Pour voir tous les détails:
     terraform output landing_zone_summary
  
  EOT

  next_steps_without_firewall = <<-EOT
  
  ✅ Landing Zone déployée avec succès!
  
  📋 Prochaines étapes:
  
  1️⃣ DÉPLOYER LE FIREWALL
     • Activer: deploy_firewall = true
     • Configurer: palo_alto_admin_ssh_key
     • Bootstrap: Configurer le Storage Account
  
  2️⃣ DÉPLOIEMENT DES WORKLOADS
     • Spoke App: ${var.spoke_app_vnet_address_space}
     • Spoke Data: ${var.spoke_data_vnet_address_space}
  
  3️⃣ CONFIGURATION RÉSEAU
     • Les routes vers le firewall sont déjà configurées
     • UDR Next Hop: ${var.firewall_trust_private_ip}
  
  📊 Pour voir tous les détails:
     terraform output landing_zone_summary
  
  EOT
}

output "next_steps" {
  description = "Prochaines étapes recommandées après déploiement"
  value       = var.deploy_firewall ? local.next_steps_with_firewall : local.next_steps_without_firewall
}
