output "bucket_name" {
  description = "Name of the bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_url" {
  description = "URL to use with the CLI."
  value       = google_storage_bucket.this.url
}
