###############################################################
# MODULE: AVL (Azure Virtual Landing Zone)
# Description: Module orchestrateur pour déployer une Landing Zone
#              Azure complète avec Hub-and-Spoke et Palo Alto Firewall
# Author: Neko-IT-Org
# Version: 1.0.0
###############################################################

###############################################################
# RESOURCE GROUPS
# Description: Création des Resource Groups pour Hub et Spokes
###############################################################
module "rg_hub" {
  source   = "../ResourceGroup"
  name     = "rg-${var.project_name}-hub-${var.environment}-${local.region_code}-01"
  location = var.location
  tags     = local.common_tags

  # Lock pour environnement production uniquement
  lock = var.environment == "prod" ? {
    kind = "CanNotDelete"
    name = "prevent-deletion-hub"
  } : null

  # Telemetry
  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_rg : null
}

module "rg_spoke_app" {
  source   = "../ResourceGroup"
  name     = "rg-${var.project_name}-spoke-app-${var.environment}-${local.region_code}-01"
  location = var.location
  tags     = merge(local.common_tags, { Tier = "application" })

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_rg : null
}

module "rg_spoke_data" {
  source   = "../ResourceGroup"
  name     = "rg-${var.project_name}-spoke-data-${var.environment}-${local.region_code}-01"
  location = var.location
  tags     = merge(local.common_tags, { Tier = "database" })

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_rg : null
}

module "rg_spoke_shared" {
  count = var.deploy_shared_services ? 1 : 0

  source   = "../ResourceGroup"
  name     = "rg-${var.project_name}-spoke-shared-${var.environment}-${local.region_code}-01"
  location = var.location
  tags     = merge(local.common_tags, { Tier = "shared-services" })

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_rg : null
}

###############################################################
# HUB VIRTUAL NETWORK
# Description: VNet Hub avec configuration pour Palo Alto
###############################################################
module "vnet_hub" {
  source              = "../Vnet"
  name                = "vnet-${var.project_name}-hub-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_hub.name
  address_space       = [var.hub_vnet_address_space]
  dns_servers         = var.custom_dns_servers
  tags                = local.common_tags

  enable_ddos_protection  = var.enable_ddos_protection
  ddos_protection_plan_id = var.ddos_protection_plan_id

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_vnet : null

  depends_on = [module.rg_hub]
}

###############################################################
# SPOKE VIRTUAL NETWORKS
# Description: VNets Spoke pour applications et données
###############################################################
module "vnet_spoke_app" {
  source              = "../Vnet"
  name                = "vnet-${var.project_name}-spoke-app-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_spoke_app.name
  address_space       = [var.spoke_app_vnet_address_space]
  dns_servers         = var.custom_dns_servers
  tags                = merge(local.common_tags, { Tier = "application" })

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_vnet : null

  depends_on = [module.rg_spoke_app]
}

module "vnet_spoke_data" {
  source              = "../Vnet"
  name                = "vnet-${var.project_name}-spoke-data-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_spoke_data.name
  address_space       = [var.spoke_data_vnet_address_space]
  dns_servers         = var.custom_dns_servers
  tags                = merge(local.common_tags, { Tier = "database" })

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_vnet : null

  depends_on = [module.rg_spoke_data]
}

module "vnet_spoke_shared" {
  count = var.deploy_shared_services ? 1 : 0

  source              = "../Vnet"
  name                = "vnet-${var.project_name}-spoke-shared-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_spoke_shared[0].name
  address_space       = [var.spoke_shared_vnet_address_space]
  dns_servers         = var.custom_dns_servers
  tags                = merge(local.common_tags, { Tier = "shared-services" })

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_vnet : null

  depends_on = [module.rg_spoke_shared]
}

###############################################################
# NETWORK SECURITY GROUPS - HUB
# Description: NSGs pour les subnets du Hub (Mgmt, Untrust, Trust)
###############################################################
module "nsg_hub_management" {
  source              = "../NSG"
  name                = "nsg-${var.project_name}-hub-mgmt-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_hub.name
  tags                = local.common_tags

  security_rules = var.nsg_hub_management_rules

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_nsg : null

  depends_on = [module.rg_hub]
}

module "nsg_hub_untrust" {
  source              = "../NSG"
  name                = "nsg-${var.project_name}-hub-untrust-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_hub.name
  tags                = local.common_tags

  security_rules = var.nsg_hub_untrust_rules

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_nsg : null

  depends_on = [module.rg_hub]
}

module "nsg_hub_trust" {
  source              = "../NSG"
  name                = "nsg-${var.project_name}-hub-trust-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_hub.name
  tags                = local.common_tags

  security_rules = var.nsg_hub_trust_rules

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_nsg : null

  depends_on = [module.rg_hub]
}

###############################################################
# NETWORK SECURITY GROUPS - SPOKES
# Description: NSGs pour les subnets des Spokes
###############################################################
module "nsg_spoke_app" {
  for_each = var.spoke_app_subnets

  source              = "../NSG"
  name                = "nsg-${var.project_name}-app-${each.key}-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_spoke_app.name
  tags                = merge(local.common_tags, { Tier = "application", Subnet = each.key })

  security_rules = each.value.nsg_rules

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_nsg : null

  depends_on = [module.rg_spoke_app]
}

module "nsg_spoke_data" {
  for_each = var.spoke_data_subnets

  source              = "../NSG"
  name                = "nsg-${var.project_name}-data-${each.key}-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_spoke_data.name
  tags                = merge(local.common_tags, { Tier = "database", Subnet = each.key })

  security_rules = each.value.nsg_rules

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_nsg : null

  depends_on = [module.rg_spoke_data]
}

###############################################################
# ROUTE TABLES
# Description: Tables de routage pour forcer le trafic via le firewall
###############################################################
module "rt_spoke_to_firewall" {
  source                        = "../RouteTable"
  name                          = "rt-${var.project_name}-spoke-to-fw-${var.environment}-${local.region_code}-01"
  location                      = var.location
  resource_group_name           = module.rg_hub.name
  bgp_route_propagation_enabled = false
  tags                          = local.common_tags

  route = [
    {
      name                   = "default-via-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_trust_private_ip
    },
    {
      name                   = "to-spoke-app"
      address_prefix         = var.spoke_app_vnet_address_space
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_trust_private_ip
    },
    {
      name                   = "to-spoke-data"
      address_prefix         = var.spoke_data_vnet_address_space
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.firewall_trust_private_ip
    }
  ]

  enable_telemetry   = var.enable_telemetry
  telemetry_settings = var.enable_telemetry ? local.telemetry_settings_rt : null

  depends_on = [module.rg_hub]
}

###############################################################
# HUB SUBNETS
# Description: Subnets pour Management, Untrust, Trust
###############################################################
module "subnets_hub" {
  source               = "../Subnet"
  resource_group_name  = module.rg_hub.name
  virtual_network_name = module.vnet_hub.name

  subnets = [
    {
      name             = "snet-management"
      address_prefixes = [var.hub_mgmt_subnet_address_prefix]
      nsg_id           = module.nsg_hub_management.id
    },
    {
      name             = "snet-untrust"
      address_prefixes = [var.hub_untrust_subnet_address_prefix]
      nsg_id           = module.nsg_hub_untrust.id
    },
    {
      name             = "snet-trust"
      address_prefixes = [var.hub_trust_subnet_address_prefix]
      nsg_id           = module.nsg_hub_trust.id
    }
  ]

  depends_on = [
    module.vnet_hub,
    module.nsg_hub_management,
    module.nsg_hub_untrust,
    module.nsg_hub_trust
  ]
}

###############################################################
# SPOKE SUBNETS - APPLICATION
###############################################################
module "subnets_spoke_app" {
  source               = "../Subnet"
  resource_group_name  = module.rg_spoke_app.name
  virtual_network_name = module.vnet_spoke_app.name

  subnets = [
    for subnet_key, subnet_config in var.spoke_app_subnets : {
      name               = "snet-${subnet_key}"
      address_prefixes   = [subnet_config.address_prefix]
      nsg_id             = module.nsg_spoke_app[subnet_key].id
      route_table_id     = module.rt_spoke_to_firewall.route_table_id
      service_endpoints  = lookup(subnet_config, "service_endpoints", [])
      delegations        = lookup(subnet_config, "delegations", [])
    }
  ]

  depends_on = [
    module.vnet_spoke_app,
    module.nsg_spoke_app,
    module.rt_spoke_to_firewall
  ]
}

###############################################################
# SPOKE SUBNETS - DATA
###############################################################
module "subnets_spoke_data" {
  source               = "../Subnet"
  resource_group_name  = module.rg_spoke_data.name
  virtual_network_name = module.vnet_spoke_data.name

  subnets = [
    for subnet_key, subnet_config in var.spoke_data_subnets : {
      name               = "snet-${subnet_key}"
      address_prefixes   = [subnet_config.address_prefix]
      nsg_id             = module.nsg_spoke_data[subnet_key].id
      route_table_id     = module.rt_spoke_to_firewall.route_table_id
      service_endpoints  = lookup(subnet_config, "service_endpoints", [])
      delegations        = lookup(subnet_config, "delegations", [])
    }
  ]

  depends_on = [
    module.vnet_spoke_data,
    module.nsg_spoke_data,
    module.rt_spoke_to_firewall
  ]
}

###############################################################
# VNET PEERINGS - HUB TO SPOKES
###############################################################
module "peering_hub_to_spoke_app" {
  source = "../VNetPeering"

  peerings = [
    {
      name                        = "peer-hub-to-spoke-app-${local.region_code}-01"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      source_virtual_network_id   = module.vnet_hub.id
      remote_virtual_network_id   = module.vnet_spoke_app.id
      remote_virtual_network_name = module.vnet_spoke_app.name
      remote_resource_group_name  = module.rg_spoke_app.name

      allow_forwarded_traffic = true
      allow_gateway_transit   = var.deploy_vpn_gateway

      create_reverse_peering          = true
      reverse_peering_name            = "peer-spoke-app-to-hub-${local.region_code}-01"
      reverse_allow_forwarded_traffic = true
      reverse_use_remote_gateways     = var.deploy_vpn_gateway
    }
  ]

  depends_on = [
    module.vnet_hub,
    module.vnet_spoke_app
  ]
}

module "peering_hub_to_spoke_data" {
  source = "../VNetPeering"

  peerings = [
    {
      name                        = "peer-hub-to-spoke-data-${local.region_code}-01"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      source_virtual_network_id   = module.vnet_hub.id
      remote_virtual_network_id   = module.vnet_spoke_data.id
      remote_virtual_network_name = module.vnet_spoke_data.name
      remote_resource_group_name  = module.rg_spoke_data.name

      allow_forwarded_traffic = true
      allow_gateway_transit   = var.deploy_vpn_gateway

      create_reverse_peering          = true
      reverse_peering_name            = "peer-spoke-data-to-hub-${local.region_code}-01"
      reverse_allow_forwarded_traffic = true
      reverse_use_remote_gateways     = var.deploy_vpn_gateway
    }
  ]

  depends_on = [
    module.vnet_hub,
    module.vnet_spoke_data
  ]
}

module "peering_hub_to_spoke_shared" {
  count = var.deploy_shared_services ? 1 : 0

  source = "../VNetPeering"

  peerings = [
    {
      name                        = "peer-hub-to-spoke-shared-${local.region_code}-01"
      source_virtual_network_name = module.vnet_hub.name
      source_resource_group_name  = module.rg_hub.name
      source_virtual_network_id   = module.vnet_hub.id
      remote_virtual_network_id   = module.vnet_spoke_shared[0].id
      remote_virtual_network_name = module.vnet_spoke_shared[0].name
      remote_resource_group_name  = module.rg_spoke_shared[0].name

      allow_forwarded_traffic = true
      allow_gateway_transit   = var.deploy_vpn_gateway

      create_reverse_peering          = true
      reverse_peering_name            = "peer-spoke-shared-to-hub-${local.region_code}-01"
      reverse_allow_forwarded_traffic = true
      reverse_use_remote_gateways     = var.deploy_vpn_gateway
    }
  ]

  depends_on = [
    module.vnet_hub,
    module.vnet_spoke_shared
  ]
}

###############################################################
# PALO ALTO VM-SERIES FIREWALL (OPTIONNEL)
# Description: Déploiement du firewall si deploy_firewall = true
###############################################################
module "palo_alto_firewall" {
  count = var.deploy_firewall ? 1 : 0

  source = "../PaloAlto"

  firewall_name       = "vm-${var.project_name}-paloalto-${var.environment}-${local.region_code}-01"
  location            = var.location
  resource_group_name = module.rg_hub.name
  tags                = merge(local.common_tags, { Component = "Firewall" })

  # VM Configuration
  vm_size                       = var.palo_alto_vm_size
  palo_version                  = var.palo_alto_version
  palo_sku                      = var.palo_alto_sku
  admin_username                = var.palo_alto_admin_username
  admin_ssh_public_key          = var.palo_alto_admin_ssh_key
  availability_zones            = var.palo_alto_availability_zones
  enable_accelerated_networking = var.palo_alto_enable_accelerated_networking

  # Network Configuration
  mgmt_subnet_id     = module.subnets_hub.id["snet-management"]
  untrust_subnet_id  = module.subnets_hub.id["snet-untrust"]
  trust_subnet_id    = module.subnets_hub.id["snet-trust"]
  mgmt_private_ip    = var.firewall_mgmt_private_ip
  untrust_private_ip = var.firewall_untrust_private_ip
  trust_private_ip   = var.firewall_trust_private_ip

  # Bootstrap Configuration
  bootstrap_storage_account    = var.bootstrap_storage_account_name
  bootstrap_storage_access_key = var.bootstrap_storage_access_key
  bootstrap_file_share         = var.bootstrap_share_name

  depends_on = [module.subnets_hub]
}
