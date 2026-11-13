# Runs against a mock AWS provider: no credentials, nothing is created.
mock_provider "aws" {}

run "defaults" {
  command = apply

  assert {
    condition     = can(regex("^p00-dev-hello-[0-9a-f]{6}$", aws_s3_bucket.this.bucket))
    error_message = "Bucket name must be <project>-<env>-hello-<6 hex chars>."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All four public-access blocks must be on."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = output.bucket_url == "s3://${output.bucket_name}"
    error_message = "bucket_url must be s3://<bucket_name>."
  }
}

run "longest_allowed_names" {
  command = apply

  variables {
    project = "abcdefgh"
    env     = "prod"
  }

  assert {
    condition     = length(aws_s3_bucket.this.bucket) <= 63
    error_message = "S3 bucket names are limited to 63 characters."
  }
}

run "rejects_invalid_project" {
  command = plan

  variables {
    project = "Bad_Name"
  }

  expect_failures = [var.project]
}

run "rejects_invalid_env" {
  command = plan

  variables {
    env = "staging"
  }

  expect_failures = [var.env]
}
