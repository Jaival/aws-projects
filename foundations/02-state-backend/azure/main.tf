# Bootstrap: creates the storage account that stores Terraform state for every other project.
# This config itself uses LOCAL state. Run it once and keep terraform.tfstate safe outside Git.

terraform {
  required_version = ">= 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
  storage_use_azuread = true
}

locals {
  tags = {
    project = "tfstate"
    env     = "shared"
    owner   = var.owner
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "azurerm_resource_group" "state" {
  name     = "rg-tfstate"
  location = var.region
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                     = "sttfstate${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "ZRS" # survive a datacentre failure; state is small, so it's cheap

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # pipelines authenticate with Entra ID (OIDC), not keys

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

# Who is running Terraform right now (you, signed in with `az login`).
data "azurerm_client_config" "current" {}

# Storage keys are disabled, so reading and writing state uses your Entra ID identity.
# That needs a *data-plane* role: being Owner of the subscription (control plane) is not enough.
# Project 09 adds the same role for the CI pipeline's identities.
resource "azurerm_role_assignment" "state_blob_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
