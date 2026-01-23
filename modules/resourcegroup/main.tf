###############################################################
# RESOURCE: time_static
# Description: Captures the timestamp at terraform apply execution time
# Usage: Used to generate the automatic "CreatedOn" tag
###############################################################
resource "time_static" "time" {}

###############################################################
# RESOURCE: azurerm_resource_group
# Description: Creates the Azure Resource Group
# Inputs:
#   - var.name: RG name (validated in variables.tf)
#   - var.location: Azure region (e.g., westeurope)
#   - var.tags: Custom tags merged with CreatedOn
# Outputs: Used by output.tf (id, name, location, tags)
###############################################################
resource "azurerm_resource_group" "this" {
  # Resource group name provided by variable
  name = var.name

  # Azure region where to deploy the RG
  location = var.location

  # Tags: Merge user tags + automatic CreatedOn tag
  # CreatedOn tag is generated in DD-MM-YYYY hh:mm format (+1h) (GTM+1: Brussels, Paris, Amsterdam time)
  tags = merge(
    var.tags,
    {
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}

###############################################################
# LOCAL: lock_configuration
# Description: Transforms the lock variable into a map for for_each
# Logic:
#   - If var.lock == null → empty map (no lock)
#   - If var.lock != null → map with "default" key (lock created)
###############################################################
locals {
  lock_configuration = var.lock == null ? {} : { default = var.lock }
}

###############################################################
# RESOURCE: azurerm_management_lock
# Description: Creates an optional management lock on the RG
# Conditions:
#   - Created only if var.lock is defined (for_each on local)
# Lock types:
#   - CanNotDelete: Prevents deletion
#   - ReadOnly: Prevents deletion AND modification
###############################################################
resource "azurerm_management_lock" "this" {
  # Iteration on local configuration (empty or with lock)
  for_each = local.lock_configuration

  # Lock type (CanNotDelete or ReadOnly)
  lock_level = each.value.kind

  # Lock name (auto-generated if not provided: "lock-CanNotDelete")

  name = coalesce(each.value.name, "lock-${each.value.kind}")
  # Scope: Applied to the created resource group
  scope = azurerm_resource_group.this.id
  # Explanatory notes based on lock type
  notes = each.value.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

###############################################################
# RESOURCE: azurerm_role_assignment
# Description: Assigns RBAC roles to the resource group
# Conditions:
#   - for_each iterates on var.role_assignments (list)
#   - Unique key: combination of principal_id + role_definition
# Use Case: Grant Reader/Contributor access to users/SPs
###############################################################
resource "azurerm_role_assignment" "this" {
  # Iteration on role assignments with unique key
  # Format: "principal_id-role_definition_id_or_name"
  for_each = { for ra in var.role_assignments : format("%s-%s", ra.principal_id, coalesce(ra.role_definition_id, ra.role_definition_name)) => ra }

  # Scope: Resource group where to apply the role
  scope = azurerm_resource_group.this.id
  # Principal ID (user, group, service principal)
  principal_id = each.value.principal_id

  # Role ID (format: /providers/Microsoft.Authorization/roleDefinitions/<guid>)
  role_definition_id = each.value.role_definition_id

  # OR role name (e.g., "Reader", "Contributor")
  role_definition_name = each.value.role_definition_name

  # Optional ABAC condition (e.g., tag-based restriction)
  condition = try(each.value.condition, null)

  # Condition version (e.g., "2.0")
  condition_version = try(each.value.condition_version, null)

  # Assignment description
  description = try(each.value.description, null)

  # Delegated Managed Identity (rare, for advanced scenarios)
  delegated_managed_identity_resource_id = try(each.value.delegated_managed_identity_resource_id, null)
}

###############################################################
# RESOURCE: azurerm_monitor_diagnostic_setting
# Description: Creates diagnostic settings for the resource group
# Condition: Created only if enable_telemetry is true
# Destinations: Log Analytics, Storage Account, Event Hub
# Use Cases:
#   - Compliance and audit logging
#   - Security monitoring
#   - Operational insights
# Note: Resource group diagnostic settings capture activity logs
###############################################################
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_telemetry && var.telemetry_settings != null ? 1 : 0

  # Diagnostic setting name
  name = "diag-${var.name}"

  # Target resource (resource group)
  target_resource_id = azurerm_resource_group.this.id

  # Log Analytics Workspace (optional)
  log_analytics_workspace_id = var.telemetry_settings.log_analytics_workspace_id

  # Storage Account for archival (optional)
  storage_account_id = var.telemetry_settings.storage_account_id

  # Event Hub for streaming (optional)
  eventhub_authorization_rule_id = var.telemetry_settings.event_hub_authorization_rule_id
  eventhub_name                  = var.telemetry_settings.event_hub_name

  ###############################################################
  # DYNAMIC BLOCK: enabled_log
  # Description: Configures which log categories to capture
  # for_each: Iterates over log_categories list
  # Default: ["Administrative"] for resource group activity logs
  ###############################################################
  dynamic "enabled_log" {
    for_each = var.telemetry_settings.log_categories
    content {
      category = enabled_log.value
    }
  }

  ###############################################################
  # DYNAMIC BLOCK: metric
  # Description: Configures which metric categories to capture
  # for_each: Iterates over metric_categories list
  # Default: ["AllMetrics"]
  # Note: Resource groups have limited metrics compared to resources
  ###############################################################
  dynamic "metric" {
    for_each = var.telemetry_settings.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }
}
