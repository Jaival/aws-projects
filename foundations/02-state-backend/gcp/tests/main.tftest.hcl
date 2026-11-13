# Plan-only: the state bucket has prevent_destroy, so a mocked apply could not be cleaned up.
mock_provider "google" {}

variables {
  gcp_project_id = "test-project"
}

run "plan" {
  command = plan

  assert {
    condition     = google_storage_bucket.state.name == "test-project-tfstate"
    error_message = "State bucket must be named <project id>-tfstate."
  }

  assert {
    condition     = google_storage_bucket.state.public_access_prevention == "enforced"
    error_message = "Public access prevention must be enforced."
  }

  assert {
    condition     = google_storage_bucket.state.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access must be on."
  }

  assert {
    condition     = google_storage_bucket.state.versioning[0].enabled == true
    error_message = "State must be versioned."
  }
}
