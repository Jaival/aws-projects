# Runs against a mock Azure provider: no credentials, nothing is created.
mock_provider "azurerm" {
  # The container's storage_account_id is validated as a real Azure resource ID,
  # so the mocked storage account needs a well-formed (fake) one.
  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/sttest"
    }
  }
}

run "defaults" {
  command = apply

  assert {
    condition     = can(regex("^stp00dev[0-9a-f]{6}$", azurerm_storage_account.this.name))
    error_message = "Storage account name must be st<project><env><6 hex chars>."
  }

  assert {
    condition     = azurerm_storage_account.this.shared_access_key_enabled == false
    error_message = "Shared access keys must be disabled."
  }

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Public blob access must be disabled."
  }

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "Minimum TLS version must be TLS1_2."
  }

  assert {
    condition     = azurerm_storage_container.this.container_access_type == "private"
    error_message = "Container must be private."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["autoshutdown"] == "true"
    error_message = "Resource group must carry autoshutdown=true by default."
  }

  assert {
    condition     = output.bucket_name == "${azurerm_storage_account.this.name}/hello"
    error_message = "bucket_name must be <storage account>/hello."
  }
}

run "longest_allowed_names" {
  command = apply

  variables {
    project = "abcdefgh"
    env     = "prod"
  }

  assert {
    condition     = length(azurerm_storage_account.this.name) <= 24
    error_message = "Azure storage account names are limited to 24 characters."
  }

  assert {
    condition     = can(regex("^[a-z0-9]+$", azurerm_storage_account.this.name))
    error_message = "Azure storage account names allow only lowercase letters and digits."
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
