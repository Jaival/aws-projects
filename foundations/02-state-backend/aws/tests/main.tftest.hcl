# Plan-only: the state bucket has prevent_destroy, so a mocked apply could not be cleaned up.
mock_provider "aws" {}

override_data {
  target          = data.aws_caller_identity.current
  override_during = plan
  values = {
    account_id = "123456789012"
  }
}

run "plan" {
  command = plan

  assert {
    condition     = aws_s3_bucket.state.bucket == "tfstate-123456789012-ap-south-1"
    error_message = "State bucket must be named tfstate-<account id>-<region>."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.state.block_public_acls,
      aws_s3_bucket_public_access_block.state.block_public_policy,
      aws_s3_bucket_public_access_block.state.ignore_public_acls,
      aws_s3_bucket_public_access_block.state.restrict_public_buckets,
    ])
    error_message = "All four public-access blocks must be on."
  }

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "State must be versioned."
  }
}
