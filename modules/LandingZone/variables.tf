###############################################################
# MODULE: AVL Landing Zone - Variables
# Description: Variables pour le déploiement de la Landing Zone Hub-and-Spoke complète
###############################################################

###############################################################
# PROJECT CONFIGURATION
###############################################################
variable "project_name" {
  description = "Nom du projet (utilisé dans les noms de ressources)"
  type        = string
  default     = "neko"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.project_name))
    error_message = "Le nom du projet doit contenir entre 2 et 10 caractères alphanumériques minuscules."
  }
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être: dev, staging ou prod."
  }
}

variable "location" {
  description = "Région Azure principale"
  type        = string
  default     = "westeurope"
}

variable "tags" {
  description = "Tags additionnels pour toutes les ressources"
  type        = map(string)
  default     = {}
}

###############################################################
# HUB VNET CONFIGURATION
###############################################################
variable "hub_vnet_address_space" {
  description = "Espace d'adressage du Hub VNet"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.hub_vnet_address_space, 0))
    error_message = "L'espace d'adressage doit être un CIDR valide."
  }
}

variable "hub_mgmt_subnet_address_prefix" {
  description = "Préfixe d'adresse pour le subnet Management"
  type        = string
  default     = "10.0.1.0/24"
}

variable "hub_untrust_subnet_address_prefix" {
  description = "Préfixe d'adresse pour le subnet Untrust"
  type        = string
  default     = "10.0.2.0/24"
}

variable "hub_trust_subnet_address_prefix" {
  description = "Préfixe d'adresse pour le subnet Trust"
  type        = string
  default     = "10.0.3.0/24"
}

###############################################################
# SPOKE VNETS CONFIGURATION
###############################################################
variable "spoke_app_vnet_address_space" {
  description = "Espace d'adressage du Spoke Application VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "spoke_data_vnet_address_space" {
  description = "Espace d'adressage du Spoke Data VNet"
  type        = string
  default     = "10.2.0.0/16"
}

variable "spoke_shared_vnet_address_space" {
  description = "Espace d'adressage du Spoke Shared Services VNet"
  type        = string
  default     = "10.3.0.0/16"
}

variable "spoke_app_subnets" {
  description = "Configuration des subnets pour le Spoke Application"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    delegations       = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
    nsg_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string)
      destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      description                = optional(string)
    }))
  }))

  default = {
    web = {
      address_prefix = "10.1.1.0/24"
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      nsg_rules = [
        {
          name                       = "Allow-HTTPS-Inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "Internet"
          destination_address_prefix = "*"
          description                = "Allow HTTPS from Internet"
        },
        {
          name                       = "Deny-All-Inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
          description                = "Deny all other inbound"
        }
      ]
    }
    app = {
      address_prefix = "10.1.2.0/24"
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      nsg_rules = [
        {
          name                       = "Allow-From-Web-Tier"
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
}

variable "spoke_data_subnets" {
  description = "Configuration des subnets pour le Spoke Data"
  type = map(object({
    address_prefix    = string
    service_endpoints = optional(list(string), [])
    delegations       = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    })), [])
    nsg_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string)
      destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      description                = optional(string)
    }))
  }))

  default = {
    database = {
      address_prefix = "10.2.1.0/24"
      service_endpoints = ["Microsoft.Sql"]
      nsg_rules = [
        {
          name                       = "Allow-SQL-From-App"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "1433"
          source_address_prefix      = "10.1.2.0/24"
          destination_address_prefix = "*"
          description                = "Allow SQL from app tier"
        }
      ]
    }
  }
}

###############################################################
# NSG RULES - HUB
###############################################################
variable "nsg_hub_management_rules" {
  description = "Règles NSG pour le subnet Management"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string)
    destination_port_range     = optional(string)
    source_address_prefix      = optional(string)
    destination_address_prefix = optional(string)
    description                = optional(string)
  }))

  default = [
    {
      name                       = "Allow-SSH-From-Admin"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "YOUR_ADMIN_IP/32"
      destination_address_prefix = "*"
      description                = "Allow SSH from admin IP"
    },
    {
      name                       = "Allow-HTTPS-From-Admin"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "YOUR_ADMIN_IP/32"
      destination_address_prefix = "*"
      description                = "Allow HTTPS from admin IP"
    },
    {
      name                       = "Deny-All-Inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Deny all other inbound"
    }
  ]
}

variable "nsg_hub_untrust_rules" {
  description = "Règles NSG pour le subnet Untrust"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string)
    destination_port_range     = optional(string)
    source_address_prefix      = optional(string)
    destination_address_prefix = optional(string)
    description                = optional(string)
  }))

  default = [
    {
      name                       = "Allow-All-Inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
      description                = "Allow all inbound (firewall will filter)"
    }
  ]
}

variable "nsg_hub_trust_rules" {
  description = "Règles NSG pour le subnet Trust"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string)
    destination_port_range     = optional(string)
      source_address_prefix      = optional(string)
      destination_address_prefix = optional(string)
      description                = optional(string)
  }))

  default = [
    {
      name                       = "Allow-From-Spokes"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "10.0.0.0/8"
      destination_address_prefix = "*"
      description                = "Allow from spoke VNets"
    }
  ]
}

###############################################################
# FIREWALL CONFIGURATION
###############################################################
variable "firewall_trust_private_ip" {
  description = "IP privée de l'interface Trust du firewall (utilisée comme next hop)"
  type        = string
  default     = "10.0.3.4"

  validation {
    condition     = can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", var.firewall_trust_private_ip))
    error_message = "L'adresse IP doit être au format valide (x.x.x.x)."
  }
}

variable "firewall_mgmt_private_ip" {
  description = "IP privée de l'interface Management du firewall"
  type        = string
  default     = "10.0.1.4"
}

variable "firewall_untrust_private_ip" {
  description = "IP privée de l'interface Untrust du firewall"
  type        = string
  default     = "10.0.2.4"
}

variable "deploy_firewall" {
  description = "Déployer le firewall Palo Alto VM-Series"
  type        = bool
  default     = false
}

###############################################################
# NETWORK SETTINGS
###############################################################
variable "custom_dns_servers" {
  description = "Serveurs DNS personnalisés pour les VNets"
  type        = list(string)
  default     = null
}

variable "enable_ddos_protection" {
  description = "Activer la protection DDoS sur le Hub VNet"
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "ID du plan de protection DDoS"
  type        = string
  default     = null
}

variable "deploy_vpn_gateway" {
  description = "Déployer une VPN Gateway dans le Hub"
  type        = bool
  default     = false
}

###############################################################
# FEATURE FLAGS
###############################################################
variable "deploy_shared_services" {
  description = "Déployer le Spoke Shared Services"
  type        = bool
  default     = false
}

variable "enable_telemetry" {
  description = "Activer la télémétrie (diagnostic settings)"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "ID du workspace Log Analytics pour la télémétrie"
  type        = string
  default     = null
}

###############################################################
# PALO ALTO SPECIFIC VARIABLES
###############################################################
variable "palo_alto_vm_size" {
  description = "Taille de la VM Palo Alto"
  type        = string
  default     = "Standard_D3_v2"
}

variable "palo_alto_version" {
  description = "Version de PAN-OS"
  type        = string
  default     = "10.2.3"
}

variable "palo_alto_sku" {
  description = "SKU Palo Alto (byol, bundle1, bundle2)"
  type        = string
  default     = "byol"

  validation {
    condition     = contains(["byol", "bundle1", "bundle2"], var.palo_alto_sku)
    error_message = "Le SKU doit être: byol, bundle1 ou bundle2."
  }
}

variable "palo_alto_admin_username" {
  description = "Nom d'utilisateur admin pour le firewall"
  type        = string
  default     = "paadmin"
}

variable "palo_alto_admin_ssh_key" {
  description = "Clé SSH publique pour l'accès admin"
  type        = string
  sensitive   = true
  default     = null
}

variable "palo_alto_availability_zones" {
  description = "Zones de disponibilité pour le firewall"
  type        = list(string)
  default     = null
}

variable "palo_alto_enable_accelerated_networking" {
  description = "Activer l'accélération réseau"
  type        = bool
  default     = false
}

variable "bootstrap_storage_account_name" {
  description = "Nom du compte de stockage pour le bootstrap"
  type        = string
  default     = null
}

variable "bootstrap_storage_access_key" {
  description = "Clé d'accès du compte de stockage"
  type        = string
  sensitive   = true
  default     = null
}

variable "bootstrap_share_name" {
  description = "Nom du partage de fichiers contenant les fichiers bootstrap"
  type        = string
  default     = "bootstrap"
}
