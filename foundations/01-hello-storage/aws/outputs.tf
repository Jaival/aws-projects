output "bucket_name" {
  description = "Name of the bucket."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_url" {
  description = "URL to use with the CLI."
  value       = "s3://${aws_s3_bucket.this.bucket}"
}
