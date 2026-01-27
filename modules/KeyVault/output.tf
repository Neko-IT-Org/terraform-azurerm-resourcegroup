# output.tf
output "id" {
  value = azurerm_key_vault.this.id
}

output "uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "ip_address" {
  value = try(azurerm_private_endpoint.this.private_service_connection[0].private_ip_address, null)
}

###############################################################
# OUTPUT: id
# Description: Key Vault resource ID
# Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<kv>
# Usage: Reference Key Vault in other modules
###############################################################
output "id" {
  description = "The Key Vault resource ID"
  value       = azurerm_key_vault.this.id
}

###############################################################
# OUTPUT: uri
# Description: Key Vault URI for API calls
# Format: https://<kv-name>.vault.azure.net/
###############################################################
output "uri" {
  description = "The Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}

###############################################################
# OUTPUT: name
# Description: Key Vault name
###############################################################
output "name" {
  description = "The Key Vault name"
  value       = azurerm_key_vault.this.name
}

###############################################################
# OUTPUT: private_endpoint_ip
# Description: Private endpoint IP address
###############################################################
output "private_endpoint_ip" {
  description = "Private endpoint IP address"
  value       = try(azurerm_private_endpoint.this.private_service_connection[0].private_ip_address, null)
}

###############################################################
# OUTPUT: private_endpoint_id
# Description: Private endpoint resource ID
###############################################################
output "private_endpoint_id" {
  description = "Private endpoint resource ID"
  value       = azurerm_private_endpoint.this.id
}

###############################################################
# OUTPUT: location
# Description: Key Vault location
###############################################################
output "location" {
  description = "Key Vault Azure region"
  value       = azurerm_key_vault.this.location
}

###############################################################
# OUTPUT: resource_group_name
# Description: Key Vault resource group
###############################################################
output "resource_group_name" {
  description = "Key Vault resource group name"
  value       = azurerm_key_vault.this.resource_group_name
}
