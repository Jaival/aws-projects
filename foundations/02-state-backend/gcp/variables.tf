variable "region" {
  description = "Region for the Terraform state storage."
  type        = string
  default     = "asia-south1"
}

variable "owner" {
  description = "Owner tag/label (lowercase)."
  type        = string
  default     = "jaival"
}

variable "gcp_project_id" {
  description = "ID of the GCP project that will hold the state bucket."
  type        = string
}
