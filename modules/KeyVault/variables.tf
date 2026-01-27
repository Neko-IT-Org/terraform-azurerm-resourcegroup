###############################################################
# MODULE: KeyVault - Variables
# Description: Variables pour Azure Key Vault SANS Private Endpoint intégré
# Note: Utilisez le module PrivateEndpoint séparé pour créer le PE
###############################################################

data "azurerm_client_config" "current" {}

###############################################################
# VARIABLE: name
# Type: string (required)
# Description: Nom du Key Vault (3-24 caractères, globalement unique)
###############################################################
variable "name" {
  type        = string
  description = "Name of the Key Vault (3-24 characters, globally unique)"

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24
    error_message = "Key Vault name must be between 3 and 24 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name))
    error_message = "Key Vault name must start with a letter, end with a letter or digit, and contain only letters, digits, and hyphens."
  }
}

###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Région Azure pour le Key Vault
###############################################################
variable "location" {
  description = "Azure region where the Key Vault will be deployed"
  type        = string
}

###############################################################
# VARIABLE: resource_group_name
# Type: string (required)
# Description: Nom du groupe de ressources
###############################################################
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

###############################################################
# VARIABLE: tenant_id
# Type: string (optional)
# Description: Azure AD tenant ID (auto-detected si null)
###############################################################
variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the Key Vault (auto-detected if null)"
  default     = null

  validation {
    condition     = var.tenant_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid GUID format."
  }
}

###############################################################
# VARIABLE: sku_name
# Type: string (optional)
# Description: SKU du Key Vault (standard ou premium pour HSM)
###############################################################
variable "sku_name" {
  type        = string
  description = "SKU name: 'standard' or 'premium' (HSM-backed)"
  default     = "premium"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be 'standard' or 'premium'."
  }
}

###############################################################
# VARIABLE: enable_rbac
# Type: bool (optional)
# Description: Activer l'autorisation RBAC (recommandé)
###############################################################
variable "enable_rbac" {
  type        = bool
  description = "Enable RBAC authorization (recommended over access policies)"
  default     = true
}

###############################################################
# VARIABLE: assign_rbac_to_current_user
# Type: bool (optional)
# Description: Assigner automatiquement le rôle Admin à l'utilisateur courant
###############################################################
variable "assign_rbac_to_current_user" {
  description = "Automatically assign Key Vault Administrator role to current user"
  type        = bool
  default     = true
}

###############################################################
# VARIABLE: enabled_for_disk_encryption
# Type: bool (optional)
# Description: Autoriser Azure Disk Encryption
###############################################################
variable "enabled_for_disk_encryption" {
  type        = bool
  description = "Enable Azure Disk Encryption to retrieve secrets and unwrap keys"
  default     = false
}

###############################################################
# VARIABLE: enabled_for_deployment
# Type: bool (optional)
# Description: Autoriser les VMs à récupérer des certificats
###############################################################
variable "enabled_for_deployment" {
  type        = bool
  description = "Enable VMs to retrieve certificates stored as secrets"
  default     = false
}

###############################################################
# VARIABLE: enabled_for_template_deployment
# Type: bool (optional)
# Description: Autoriser ARM templates à récupérer des secrets
###############################################################
variable "enabled_for_template_deployment" {
  type        = bool
  description = "Enable ARM templates to retrieve secrets"
  default     = false
}

###############################################################
# VARIABLE: soft_delete_retention_days
# Type: number (optional)
# Description: Jours de rétention pour soft delete (7-90)
###############################################################
variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain soft-deleted Key Vault (7-90)"
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

###############################################################
# VARIABLE: purge_protection_enabled
# Type: bool (optional)
# Description: Activer la protection contre la purge (irréversible!)
###############################################################
variable "purge_protection_enabled" {
  type        = bool
  description = "Enable purge protection (IRREVERSIBLE once enabled!)"
  default     = true
}

###############################################################
# VARIABLE: public_network_access_enabled
# Type: bool (optional)
# Description: Autoriser l'accès réseau public (désactiver en prod)
###############################################################
variable "public_network_access_enabled" {
  type        = bool
  description = "Enable public network access (disable in production)"
  default     = false
}

###############################################################
# VARIABLE: network_acls
# Type: object (optional)
# Description: Configuration des ACLs réseau
###############################################################
variable "network_acls" {
  description = "Network ACLs configuration for Key Vault firewall"
  type = object({
    default_action = string                    # "Allow" or "Deny"
    bypass         = string                    # "AzureServices" or "None"
    ip_rules       = optional(list(string), []) # List of allowed public IPs
    subnet_ids     = optional(list(string), []) # List of allowed subnet IDs
  })
  default  = null
  nullable = true

  validation {
    condition = var.network_acls == null || contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be 'Allow' or 'Deny'."
  }

  validation {
    condition = var.network_acls == null || contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be 'AzureServices' or 'None'."
  }
}

###############################################################
# VARIABLE: tags
# Type: map(string) (optional)
# Description: Tags à appliquer au Key Vault
###############################################################
variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Key Vault"
  default     = {}
}

###############################################################
# VARIABLE: enable_telemetry
# Type: bool (optional)
# Description: Activer les paramètres de diagnostic
###############################################################
variable "enable_telemetry" {
  description = "Enable diagnostic settings for Key Vault telemetry"
  type        = bool
  default     = false
}

###############################################################
# VARIABLE: telemetry_settings
# Type: object (optional)
# Description: Configuration de la télémétrie
###############################################################
variable "telemetry_settings" {
  description = "Diagnostic settings configuration for telemetry"
  type = object({
    log_analytics_workspace_id      = optional(string)
    storage_account_id              = optional(string)
    event_hub_authorization_rule_id = optional(string)
    event_hub_name                  = optional(string)
    log_categories                  = optional(list(string), ["AuditEvent", "AzurePolicyEvaluationDetails"])
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
    error_message = "If telemetry_settings is provided, at least one destination must be specified."
  }
}
