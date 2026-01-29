###############################################################
# MODULE: Landing Zone
# Description: Azure Landing Zone - Resource Group foundation
# Author: Neko-IT-Org
# Version: 2.0.0
###############################################################

###############################################################
# RESOURCE GROUP
###############################################################
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project_name}-lz-${var.environment}-${local.region_code}-01"
  location = var.location
  tags     = local.common_tags
}