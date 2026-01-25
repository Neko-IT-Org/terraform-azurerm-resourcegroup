###############################################################
# MODULE: AVL Landing Zone - Locals
# Description: Valeurs locales calculées pour simplifier la configuration
###############################################################

locals {
  ###############################################################
  # REGION CODE MAPPING
  ###############################################################
  region_codes = {
    "westeurope"    = "weu"
    "northeurope"   = "neu"
    "eastus"        = "eus"
    "westus"        = "wus"
    "francecentral" = "frc"
    "germanywest"   = "gew"
    "uksouth"       = "uks"
  }

  region_code = lookup(local.region_codes, var.location, "weu")

  ###############################################################
  # COMMON TAGS
  ###############################################################
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "AVL-LandingZone"
    }
  )

  ###############################################################
  # TELEMETRY SETTINGS
  ###############################################################
  telemetry_settings_rg = var.enable_telemetry && var.log_analytics_workspace_id != null ? {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    storage_account_id              = null
    event_hub_authorization_rule_id = null
    event_hub_name                  = null
    log_categories                  = ["Administrative"]
    metric_categories               = ["AllMetrics"]
  } : null

  telemetry_settings_vnet = var.enable_telemetry && var.log_analytics_workspace_id != null ? {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    storage_account_id              = null
    event_hub_authorization_rule_id = null
    event_hub_name                  = null
    log_categories                  = ["VMProtectionAlerts"]
    metric_categories               = ["AllMetrics"]
  } : null

  telemetry_settings_nsg = var.enable_telemetry && var.log_analytics_workspace_id != null ? {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    storage_account_id              = null
    event_hub_authorization_rule_id = null
    event_hub_name                  = null
    log_categories                  = ["NetworkSecurityGroupEvent", "NetworkSecurityGroupRuleCounter"]
    metric_categories               = ["AllMetrics"]
  } : null

  telemetry_settings_rt = var.enable_telemetry && var.log_analytics_workspace_id != null ? {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    storage_account_id              = null
    event_hub_authorization_rule_id = null
    event_hub_name                  = null
    metric_categories               = ["AllMetrics"]
  } : null

  ###############################################################
  # NAMING PREFIXES
  ###############################################################
  prefix_hub        = "${var.project_name}-hub-${var.environment}-${local.region_code}"
  prefix_spoke_app  = "${var.project_name}-spoke-app-${var.environment}-${local.region_code}"
  prefix_spoke_data = "${var.project_name}-spoke-data-${var.environment}-${local.region_code}"
  prefix_spoke_shared = "${var.project_name}-spoke-shared-${var.environment}-${local.region_code}"

  ###############################################################
  # COMPUTED VALUES
  ###############################################################
  # Déterminer si on doit créer des locks (prod uniquement)
  create_locks = var.environment == "prod"

  # Liste de tous les spokes déployés
  deployed_spokes = concat(
    ["app", "data"],
    var.deploy_shared_services ? ["shared"] : []
  )
}
