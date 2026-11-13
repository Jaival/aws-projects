terraform {
  required_version = ">= 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}

  # The subscription is read from the ARM_SUBSCRIPTION_ID environment variable
  # (or set subscription_id here). azurerm 4.x requires one of the two.

  # Talk to blob storage with your Entra ID identity instead of storage account keys.
  storage_use_azuread = true
}

locals {
  tags = {
    project      = var.project
    env          = var.env
    owner        = var.owner
    autoshutdown = tostring(var.autoshutdown) # "true" / "false" — tag values must be strings
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

# Azure needs a resource group before anything else. AWS and GCP have no equivalent.
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.project}-${var.env}-hello"
  location = var.region
  tags     = local.tags
}

# Storage account names: 3–24 chars, lowercase letters and digits only, globally unique.
resource "azurerm_storage_account" "this" {
  name                     = "st${var.project}${var.env}${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # cheapest; ZRS/GZRS are covered in project 02

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false # no anonymous/public blob access
  shared_access_key_enabled       = false # Entra ID (identity-based) access only — no keys to leak

  blob_properties {
    versioning_enabled = true
  }

  tags = local.tags
}

# The equivalent of an S3/GCS bucket is a *container* inside the storage account.
resource "azurerm_storage_container" "this" {
  name                  = "hello"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
