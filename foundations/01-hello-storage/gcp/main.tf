terraform {
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region

  # GCP calls tags "labels": lowercase keys and values only.
  default_labels = {
    project      = var.project
    env          = var.env
    owner        = var.owner
    autoshutdown = tostring(var.autoshutdown) # "true" / "false" — tag values must be strings
  }
}

# Bucket names are globally unique across all of Google Cloud.
resource "random_id" "suffix" {
  byte_length = 3
}

resource "google_storage_bucket" "this" {
  name          = "${var.project}-${var.env}-hello-${random_id.suffix.hex}"
  location      = upper(var.region) # a single region; dual-/multi-region buckets are covered in project 02
  force_destroy = true

  uniform_bucket_level_access = true       # IAM only, no per-object ACLs
  public_access_prevention    = "enforced" # can never be made public

  versioning {
    enabled = true
  }
}
