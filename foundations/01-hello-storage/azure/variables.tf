# Same variables on every cloud — only the default region differs.

variable "project" {
  description = "Short project code, used in names and tags/labels."
  type        = string
  default     = "p00"

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.project))
    error_message = "Use 2–8 lowercase letters or digits (works for every cloud's naming rules)."
  }
}

variable "env" {
  description = "Environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.env)
    error_message = "env must be dev, test or prod."
  }
}

variable "region" {
  description = "Region to deploy into."
  type        = string
  default     = "centralindia"
}

variable "owner" {
  description = "Owner tag/label (lowercase so it is valid on GCP too)."
  type        = string
  default     = "jaival"
}
