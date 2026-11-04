output "backend_config" {
  description = "Paste into a project's backend block (change `key` per project)."
  value       = <<-EOT
    terraform {
      backend "s3" {
        bucket       = "${aws_s3_bucket.state.bucket}"
        key          = "projects/p01/terraform.tfstate"
        region       = "${var.region}"
        use_lockfile = true # native S3 locking, no DynamoDB table needed
        encrypt      = true
      }
    }
  EOT
}
