resource "time_static" "time" {}

###############################################################
# Creates an Azure Key Vault with configurable access, network, and security settings.
###############################################################
resource "azurerm_key_vault" "this" {
  name                            = var.name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.tenant_id
  sku_name                        = var.sku_name
  rbac_authorization_enabled      = var.enable_rbac
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  # Optionally configure network ACLs if provided.
  dynamic "network_acls" {
    for_each = (
      var.network_acls != null ? [1] : []
    )
    content {
      default_action             = var.network_acls.default_action
      bypass                     = var.network_acls.bypass
      ip_rules                   = try(var.network_acls.ip_rules, [])
      virtual_network_subnet_ids = try(var.network_acls.subnet_ids, [])
    }
  }
  # Assign tags for resource organization and management.
  tags = merge(
    var.tags,
    {
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}

###############################################################
# Local values for constructing resource names and prefixes for private endpoint.
###############################################################
locals {
  # Si var.name = "kv-neko-lab-weu-01"
  # Alors pep_name = "pep-neko-lab-kv-weu-01"
  pep_base_name = replace(var.name, "kv-", "")
  pep_name      = "pep-${local.pep_base_name}-kv"
  psc_name      = "psc-${local.pep_base_name}-kv"
  ipc_name      = "ipc-${local.pep_base_name}-kv"
}

###############################################################
# Creates a private endpoint for the Key Vault, enabling secure access from a specified subnet.
###############################################################
resource "azurerm_private_endpoint" "this" {
  name                = local.pep_name
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id
  tags = merge(
    var.tags,
    {
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )


  # Defines the private service connection to the Key Vault.
  private_service_connection {
    name                           = local.psc_name
    private_connection_resource_id = azurerm_key_vault.this.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
  # Optionally configure a static private IP address for the endpoint if provided.
  dynamic "ip_configuration" {
    for_each = var.private_ip_address != null ? [1] : []
    content {
      name               = local.ipc_name
      private_ip_address = var.private_ip_address
      subresource_name   = "Vault"
      member_name        = "default"
    }
  }

  # Optionally link the private endpoint to a private DNS zone group if provided.
  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_group != null ? [1] : []

    content {
      name                 = "link2dnszone"
      private_dns_zone_ids = var.private_dns_zone_group.private_dns_zone_ids
    }
  }


}

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

resource "azurerm_role_assignment" "this" {
  count                = var.assign_rbac_to_current_user ? 1 : 0
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
