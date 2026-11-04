terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  # Every resource this provider creates gets these tags automatically.
  default_tags {
    tags = {
      project = var.project
      env     = var.env
      owner   = var.owner
    }
  }
}

# S3 bucket names are globally unique across ALL AWS customers, so add a random suffix.
resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.project}-${var.env}-hello-${random_id.suffix.hex}"
  force_destroy = true # lets `terraform destroy` delete a non-empty bucket (fine for a lab, not for prod)
}

# Block every form of public access. (New buckets do this by default; being explicit documents intent.)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keep old versions of objects so overwrites and deletes can be undone.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt at rest with S3-managed keys (SSE-S3). Use "aws:kms" + a KMS key for customer-managed keys.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
