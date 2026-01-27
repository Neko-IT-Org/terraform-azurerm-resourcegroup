# variables.tf
data "azurerm_client_config" "current" {}

variable "name" {
  type        = string
  description = "Name of the Key Vault."
}

###############################################################
# VARIABLE: location
# Type: string (required)
# Description: Azure region for the Key Vault
# Example: "westeurope"
###############################################################
variable "location" {
  description = "Azure region where the Key Vault will be deployed"
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID for the Key Vault"
  default     = null

  validation {
    condition     = var.tenant_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid GUID format."
  }
}

variable "sku_name" {
  type    = string
  default = "premium"
}

variable "enable_rbac" {
  type    = bool
  default = true
}

variable "enabled_for_disk_encryption" {
  type    = bool
  default = false
}

variable "enabled_for_deployment" {
  type    = bool
  default = false
}

variable "enabled_for_template_deployment" {
  type    = bool
  default = false
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain soft-deleted Key Vault (7-90)"
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  type    = bool
  default = true
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "network_acls" {
  description = "Optional network ACLs config"
  type = object({
    default_action = string
    bypass         = string
    ip_rules       = optional(list(string))
    subnet_ids     = optional(list(string))
  })
  default  = null
  nullable = true
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_id" {
  type = string
}

variable "private_ip_address" {
  type    = string
  default = null
}

variable "assign_rbac_to_current_user" {
  description = "Automatically assign Key Vault Administrator to current user"
  type        = bool
  default     = true
}

variable "private_dns_zone_group" {
  type = object({
    dns_name             = optional(string)
    private_dns_zone_ids = optional(list(string))
  })
  default = null
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Number of days to retain soft-deleted Key Vault (7-90)"
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "enable_telemetry" {
  description = "Enable diagnostic settings for Key Vault telemetry"
  type        = bool
  default     = false
}

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
