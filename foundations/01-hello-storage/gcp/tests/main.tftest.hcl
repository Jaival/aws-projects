# Runs against a mock Google provider: no credentials, nothing is created.
mock_provider "google" {}

variables {
  gcp_project_id = "test-project"
}

run "defaults" {
  command = apply

  assert {
    condition     = can(regex("^p00-dev-hello-[0-9a-f]{6}$", google_storage_bucket.this.name))
    error_message = "Bucket name must be <project>-<env>-hello-<6 hex chars>."
  }

  assert {
    condition     = google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "Public access prevention must be enforced."
  }

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access must be on."
  }

  assert {
    condition     = google_storage_bucket.this.location == "ASIA-SOUTH1"
    error_message = "Bucket must be in ASIA-SOUTH1 by default."
  }

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled == true
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = output.bucket_name == google_storage_bucket.this.name
    error_message = "bucket_name must equal the bucket's name."
  }
}

run "longest_allowed_names" {
  command = apply

  variables {
    project = "abcdefgh"
    env     = "prod"
  }

  assert {
    condition     = length(google_storage_bucket.this.name) <= 63
    error_message = "GCS bucket names are limited to 63 characters."
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
