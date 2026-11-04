variable "region" {
  description = "Region for the Terraform state storage."
  type        = string
  default     = "centralindia"
}

variable "owner" {
  description = "Owner tag/label (lowercase)."
  type        = string
  default     = "jaival"
}
