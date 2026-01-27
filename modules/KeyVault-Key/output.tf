###############################################################
# OUTPUT: keys
# Description: Full azurerm_key_vault_key resources
# Format: { "key1" = <full resource object>, ... }
# Usage: Access all key attributes
###############################################################
output "keys" {
  description = "Full azurerm_key_vault_key resources by key map key"
  value       = azurerm_key_vault_key.this
}

###############################################################
# OUTPUT: ids
# Description: Versioned Key IDs
# Format: { "key1" = "https://<kv>.vault.azure.net/keys/<name>/<version>", ... }
# Usage: Reference specific key version
###############################################################
output "ids" {
  description = "Key IDs (versioned) - use for specific version reference"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.id }
}

###############################################################
# OUTPUT: versionless_ids
# Description: Versionless Key IDs
# Format: { "key1" = "https://<kv>.vault.azure.net/keys/<name>", ... }
# Usage: Auto-rotation support (always latest version)
###############################################################
output "versionless_ids" {
  description = "Key IDs without version (useful for CMK auto-rotation consumers)"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.versionless_id }
}

###############################################################
# OUTPUT: names
# Description: Key names
# Format: { "key1" = "key1", ... }
###############################################################
output "names" {
  description = "Map of key names"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.name }
}

###############################################################
# OUTPUT: key_types
# Description: Key types
# Format: { "key1" = "RSA", ... }
###############################################################
output "key_types" {
  description = "Map of key types"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.key_type }
}

###############################################################
# OUTPUT: expiration_dates
# Description: Key expiration dates
# Format: { "key1" = "2026-01-27T00:00:00Z", ... }
###############################################################
output "expiration_dates" {
  description = "Map of key expiration dates"
  value       = { for k, v in azurerm_key_vault_key.this : k => v.expiration_date }
}
