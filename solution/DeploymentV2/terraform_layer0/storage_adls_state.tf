locals {
  stateaccountname = "gf6state"
}

#note: Swapped from native tf due to https://github.com/hashicorp/terraform-provider-azurerm/issues/16335
resource "azapi_resource" "adls_state" {
  type      = "Microsoft.Storage/storageAccounts@2022-05-01"
  name      = local.stateaccountname
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  location  = var.resource_location
  
  body = jsonencode({
    kind = "StorageV2"
    sku  = {
      name = "Standard_GRS"
    }    
    properties = {
      isHnsEnabled = true,
      minimumTlsVersion = "TLS1_2"
      publicNetworkAccess = var.is_vnet_isolated ? "Disabled" : "Enabled"
    networkAcls = {
      defaultAction = "Deny",
      bypass = "AzureServices,Metrics"
      ipRules = var.is_vnet_isolated ? [{value = var.ip_address, action = "Allow"}] : [] 
    }      
    }
  })
}



resource "azurerm_role_assignment" "adls_state_deployment_agents" {
  for_each = {
    for ro in var.resource_owners : ro => ro
  }    
  scope                = azapi_resource.adls_state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_private_endpoint" "adls_state_storage_private_endpoint_with_dns" {
  count               = var.deploy_adls && var.is_vnet_isolated ? 1 : 0
  name                = "${local.stateaccountname}-blob-plink"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  subnet_id           = local.plink_subnet_id

  private_service_connection {
    name                           = "${local.stateaccountname}-blob-plink-conn"
    private_connection_resource_id = azapi_resource.adls_state.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "privatednszonegroupstorageblob"
    private_dns_zone_ids = [local.private_dns_zone_blob_id]
  }

  depends_on = [
    azapi_resource.adls_state
  ]

  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_private_endpoint" "adls_dfs_state_storage_private_endpoint_with_dns" {
  count               = var.deploy_adls && var.is_vnet_isolated ? 1 : 0
  name                = "${local.stateaccountname}-dfs-plink"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  subnet_id           = local.plink_subnet_id

  private_service_connection {
    name                           = "${local.stateaccountname}-dfs-plink-conn"
    private_connection_resource_id = azapi_resource.adls_state.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  private_dns_zone_group {
    name                 = "privatednszonegroupstoragedfs"
    private_dns_zone_ids = [local.private_dns_zone_dfs_id]
  }

  depends_on = [
    azapi_resource.adls_state
  ]

  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

