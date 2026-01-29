###############################################################
# MODULE: Landing Zone - Variables
# Description: Input variables for Landing Zone deployment
###############################################################

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.project_name))
    error_message = "Project name must be 2-10 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: dev, uat, or prod."
  }
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "germanywestcentral"
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}