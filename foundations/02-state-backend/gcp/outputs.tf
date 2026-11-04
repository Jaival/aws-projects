output "backend_config" {
  description = "Paste into a project's backend block (change `prefix` per project)."
  value       = <<-EOT
    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.state.name}"
        prefix = "projects/p01"
      }
    }
  EOT
}
