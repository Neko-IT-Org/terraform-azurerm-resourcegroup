#################################################################################
# Module ResourceGroup - Groupe de Ressources Azure
#################################################################################
# Description: Ce module crée et gère un groupe de ressources Azure, qui est 
#              le conteneur logique pour organiser et gérer les ressources Azure.
#              Il gère également les verrous de gestion et les attributions de rôles.
#################################################################################

###############################################################
# Ressource Time Static
###############################################################
# Capture le timestamp exact de la première application Terraform
# Utilisée pour ajouter le tag 'CreatedOn' au groupe de ressources
resource "time_static" "time" {}

###############################################################
# Ressource: Groupe de Ressources Azure
###############################################################
# Description: Crée un groupe de ressources Azure dans une région spécifiée
# Attributs principaux:
#   - name: Nom du groupe de ressources (fourni via variable)
#   - location: Région Azure (fourni via variable)
#   - tags: Étiquettes pour l'organisation et le suivi des ressources
resource "azurerm_resource_group" "this" {
  # Nom du groupe de ressources
  name = var.name

  # Région Azure où créer le groupe de ressources (ex: "eastus", "westeurope")
  location = var.location

  # Tags pour classifier et organiser les ressources
  # Fusionne les tags fournis par l'utilisateur avec un tag système 'CreatedOn'
  tags = merge(
    var.tags,
    {
      # 'CreatedOn' tag contient la date/heure de création formatée DD-MM-YYYY hh:mm
      # Un décalage d'une heure est appliqué au timestamp
      CreatedOn = formatdate("DD-MM-YYYY hh:mm", timeadd(time_static.time.id, "1h"))
    }
  )
}

###############################################################
# Ressource: Verrous de Gestion (Management Locks)
###############################################################
# Description: Optionnellement crée des verrous de gestion sur le groupe de ressources
#              pour prévenir les suppressions accidentelles.
# Utilisation: Les verrous peuvent être de deux types:
#   - "CanNotDelete": Empêche la suppression du groupe de ressources
#   - "ReadOnly": Empêche la modification et la suppression
#
# Configuration Locale: Convertit la variable lock en map (vide si lock est null)
locals {
  lock_configuration = var.lock == null ? {} : { default = var.lock }
}

# Crée les verrous définis par la configuration locale
# Le bloc for_each itère sur chaque élément de lock_configuration
resource "azurerm_management_lock" "this" {
  for_each   = local.lock_configuration
  
  # Type de verrou: "CanNotDelete" ou "ReadOnly"
  lock_level = each.value.kind
  
  # Nom du verrou (utilise le nom fourni ou génère "lock-{kind}")
  name       = coalesce(each.value.name, "lock-${each.value.kind}")
  
  # Scope du verrou (appliqué au groupe de ressources créé)
  scope      = azurerm_resource_group.this.id
  
  # Notes descriptives selon le type de verrou
  notes      = each.value.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

###############################################################
# Ressource: Attributions de Rôles RBAC
###############################################################
# Description: Optionnellement assigne des rôles Azure RBAC (Role-Based Access Control)
#              à des entités de sécurité (utilisateurs, groupes, applications, etc.)
#              sur le groupe de ressources.
# 
# Utilisation: Chaque attribution contient:
#   - principal_id: ID de l'entité (utilisateur, groupe, service principal, etc.)
#   - role_definition_id OU role_definition_name: Le rôle à assigner
#   - condition: Condition optionnelle pour l'accès conditionnel
#   - condition_version: Version de la condition (ex: "2.0")
#   - description: Description de l'attribution
#   - delegated_managed_identity_resource_id: Identité gérée déléguée (optionnel)
#
# Clé Unique: Chaque attribution est identifiée par "{principal_id}-{role_id_ou_nom}"
resource "azurerm_role_assignment" "this" {
  for_each = { for ra in var.role_assignments : format("%s-%s", ra.principal_id, coalesce(ra.role_definition_id, ra.role_definition_name)) => ra }
  
  # Scope de l'attribution (groupe de ressources créé)
  scope                                  = azurerm_resource_group.this.id
  
  # ID du principal (utilisateur, groupe, service principal)
  principal_id                           = each.value.principal_id
  
  # ID du rôle (optionnel si role_definition_name est fourni)
  role_definition_id                     = each.value.role_definition_id
  
  # Nom du rôle (optionnel si role_definition_id est fourni)
  # Exemples: "Contributor", "Reader", "Owner", "Network Contributor"
  role_definition_name                   = each.value.role_definition_name
  
  # Conditions d'accès avancées (optionnel)
  condition                              = try(each.value.condition, null)
  
  # Version de la condition (optionnel)
  condition_version                      = try(each.value.condition_version, null)
  
  # Description de l'attribution (optionnel)
  description                            = try(each.value.description, null)
  
  # Identité gérée déléguée pour les attributions avec conditions (optionnel)
  delegated_managed_identity_resource_id = try(each.value.delegated_managed_identity_resource_id, null)
}
