output "bucket_name" {
  description = "Storage account / container (Azure's equivalent of a bucket)."
  value       = "${azurerm_storage_account.this.name}/${azurerm_storage_container.this.name}"
}

output "bucket_url" {
  description = "URL of the container."
  value       = "${azurerm_storage_account.this.primary_blob_endpoint}${azurerm_storage_container.this.name}"
}
