###############################################################
# MODULE: KeyVault - Main
# Description: Azure Key Vault SANS Private Endpoint intégré
# Note: Utilisez le module PrivateEndpoint séparé pour créer le PE
###############################################################

resource "time_static" "time" {}

###############################################################
# RESOURCE: Azure Key Vault
# Description: Crée un Azure Key Vault avec configuration sécurisée
###############################################################
resource "azurerm_key_vault" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Tenant ID (auto-detected si null)
  tenant_id = coalesce(var.tenant_id, data.azurerm_client_config.current.tenant_id)

  # SKU
  sku_name = var.sku_name

  # Authorization
  rbac_authorization_enabled = var.enable_rbac

  # Encryption enablement
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment

  # Data protection
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = var.purge_protection_enabled

  # Network access
  public_network_access_enabled = var.public_network_access_enabled

  # Network ACLs (optionnel)
  dynamic "network_acls" {
    for_each = var.network_acls != null ? [var.network_acls] : []
    content {
      default_action             = network_acls.value.default_action
      bypass                     = network_acls.value.bypass
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.subnet_ids
    }
  }

  # Tags avec timestamp de création
  tags = merge(
    var.tags,
    {
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}

###############################################################
# RESOURCE: RBAC Assignment
# Description: Assigne le rôle Key Vault Administrator à l'utilisateur courant
###############################################################
resource "azurerm_role_assignment" "this" {
  count = var.assign_rbac_to_current_user ? 1 : 0

  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

###############################################################
# RESOURCE: Diagnostic Settings
# Description: Configure la télémétrie vers Log Analytics/Storage/EventHub
###############################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_telemetry && var.telemetry_settings != null ? 1 : 0

  name               = "diag-${var.name}"
  target_resource_id = azurerm_key_vault.this.id

  log_analytics_workspace_id     = var.telemetry_settings.log_analytics_workspace_id
  storage_account_id             = var.telemetry_settings.storage_account_id
  eventhub_authorization_rule_id = var.telemetry_settings.event_hub_authorization_rule_id
  eventhub_name                  = var.telemetry_settings.event_hub_name

  dynamic "enabled_log" {
    for_each = var.telemetry_settings.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = var.telemetry_settings.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}
