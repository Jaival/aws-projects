output "backend_config" {
  description = "Paste into a project's backend block (change `key` per project)."
  value       = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.state.name}"
        storage_account_name = "${azurerm_storage_account.state.name}"
        container_name       = "${azurerm_storage_container.state.name}"
        key                  = "projects/p01/terraform.tfstate"
        use_azuread_auth     = true # Entra ID instead of storage keys
      }
    }
  EOT
}
