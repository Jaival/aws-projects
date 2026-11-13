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
  default     = "asia-south1"
}

variable "owner" {
  description = "Owner tag/label (lowercase so it is valid on GCP too)."
  type        = string
  default     = "jaival"
}

variable "autoshutdown" {
  description = "May the cost watchdog (project 05) stop these resources outside working hours?"
  type        = bool
  default     = true
}

# GCP is the only cloud that needs this: every resource lives inside a project.
# (On AWS the account comes from your credentials; on Azure the subscription does.)
variable "gcp_project_id" {
  description = "ID of the GCP project to deploy into."
  type        = string
}
