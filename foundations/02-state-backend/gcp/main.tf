# Bootstrap: creates the GCS bucket that stores Terraform state for every other project.
# This config itself uses LOCAL state. Run it once and keep terraform.tfstate safe outside Git.

terraform {
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region

  default_labels = {
    project      = "tfstate"
    env          = "shared"
    owner        = var.owner
    autoshutdown = "false" # state storage must never be stopped or cleaned up by the watchdog
  }
}

resource "google_storage_bucket" "state" {
  # Project IDs are globally unique, so this bucket name is too.
  name     = "${var.gcp_project_id}-tfstate"
  location = upper(var.region)

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true # the GCS backend locks with a lock file; versioning lets you recover old state
  }

  # Keep the 10 most recent non-current versions of each state file.
  lifecycle_rule {
    condition {
      num_newer_versions = 10
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
