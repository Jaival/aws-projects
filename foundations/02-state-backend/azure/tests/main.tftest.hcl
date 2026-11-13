# Plan-only: the state storage account has prevent_destroy, so a mocked apply could not be cleaned up.
mock_provider "azurerm" {}

run "plan" {
  command = plan

  assert {
    condition     = azurerm_resource_group.state.name == "rg-tfstate"
    error_message = "Resource group must be named rg-tfstate."
  }

  assert {
    condition     = azurerm_storage_account.state.account_replication_type == "ZRS"
    error_message = "State storage must use ZRS replication."
  }

  assert {
    condition     = azurerm_storage_account.state.shared_access_key_enabled == false
    error_message = "Shared access keys must be disabled."
  }

  assert {
    condition     = azurerm_storage_account.state.min_tls_version == "TLS1_2"
    error_message = "Minimum TLS version must be TLS1_2."
  }

  assert {
    condition     = azurerm_storage_container.state.name == "tfstate"
    error_message = "Container must be named tfstate."
  }

  assert {
    condition     = azurerm_role_assignment.state_blob_contributor.role_definition_name == "Storage Blob Data Contributor"
    error_message = "Role assignment must grant Storage Blob Data Contributor."
  }

  assert {
    condition     = azurerm_resource_group.state.tags["autoshutdown"] == "false"
    error_message = "State resources must carry autoshutdown=false."
  }
}
