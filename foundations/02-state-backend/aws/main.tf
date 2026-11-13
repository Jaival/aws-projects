# Bootstrap: creates the S3 bucket that stores Terraform state for every other project.
# This config itself uses LOCAL state (chicken-and-egg). Run it once, keep the
# terraform.tfstate file safe outside Git (it's ignored by .gitignore).

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project      = "tfstate"
      env          = "shared"
      owner        = var.owner
      autoshutdown = "false" # state storage must never be stopped or cleaned up by the watchdog
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  # The account ID makes the name unique without a random suffix.
  bucket = "tfstate-${data.aws_caller_identity.current.account_id}-${var.region}"

  lifecycle {
    prevent_destroy = true # losing state means Terraform forgets everything it built
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled" # recover from a corrupted or accidentally deleted state file
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Without this, every old version of every state file is kept (and billed) forever.
# Keep the 10 newest old versions; the GCP backend does the same with a lifecycle_rule.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {} # applies to every object in the bucket

    noncurrent_version_expiration {
      newer_noncurrent_versions = 10
      noncurrent_days           = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

# Only allow HTTPS access to the state bucket.
resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.state]
}
