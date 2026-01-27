###############################################################
# MODULE: KeyVault - Outputs
# Description: Outputs du Key Vault (sans Private Endpoint)
###############################################################

###############################################################
# OUTPUT: id
# Description: ID de ressource du Key Vault
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv>
###############################################################
output "id" {
  description = "The Key Vault resource ID"
  value       = azurerm_key_vault.this.id
}

###############################################################
# OUTPUT: uri
# Description: URI du Key Vault pour les appels API
# Format: https://<kv-name>.vault.azure.net/
###############################################################
output "uri" {
  description = "The Key Vault URI (e.g., https://kv-name.vault.azure.net/)"
  value       = azurerm_key_vault.this.vault_uri
}

###############################################################
# OUTPUT: name
# Description: Nom du Key Vault
###############################################################
output "name" {
  description = "The Key Vault name"
  value       = azurerm_key_vault.this.name
}

###############################################################
# OUTPUT: location
# Description: Région Azure du Key Vault
###############################################################
output "location" {
  description = "Key Vault Azure region"
  value       = azurerm_key_vault.this.location
}

###############################################################
# OUTPUT: resource_group_name
# Description: Groupe de ressources du Key Vault
###############################################################
output "resource_group_name" {
  description = "Key Vault resource group name"
  value       = azurerm_key_vault.this.resource_group_name
}

###############################################################
# OUTPUT: tenant_id
# Description: Tenant ID du Key Vault
###############################################################
output "tenant_id" {
  description = "Key Vault tenant ID"
  value       = azurerm_key_vault.this.tenant_id
}

###############################################################
# OUTPUT: sku_name
# Description: SKU du Key Vault
###############################################################
output "sku_name" {
  description = "Key Vault SKU (standard or premium)"
  value       = azurerm_key_vault.this.sku_name
}

###############################################################
# OUTPUT: rbac_enabled
# Description: Indique si RBAC est activé
###############################################################
output "rbac_enabled" {
  description = "Whether RBAC authorization is enabled"
  value       = azurerm_key_vault.this.rbac_authorization_enabled
}

###############################################################
# OUTPUT: purge_protection_enabled
# Description: Indique si la protection contre la purge est activée
###############################################################
output "purge_protection_enabled" {
  description = "Whether purge protection is enabled"
  value       = azurerm_key_vault.this.purge_protection_enabled
}

###############################################################
# OUTPUT: soft_delete_retention_days
# Description: Jours de rétention pour soft delete
###############################################################
output "soft_delete_retention_days" {
  description = "Soft delete retention days"
  value       = azurerm_key_vault.this.soft_delete_retention_days
}

###############################################################
# OUTPUT: public_network_access_enabled
# Description: Indique si l'accès réseau public est activé
###############################################################
output "public_network_access_enabled" {
  description = "Whether public network access is enabled"
  value       = azurerm_key_vault.this.public_network_access_enabled
}

###############################################################
# OUTPUT: tags
# Description: Tags appliqués au Key Vault
###############################################################
output "tags" {
  description = "Tags applied to the Key Vault"
  value       = azurerm_key_vault.this.tags
}
