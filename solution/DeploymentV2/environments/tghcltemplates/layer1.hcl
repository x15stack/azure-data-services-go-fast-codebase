locals {
  common_vars = jsondecode(file("../../../bin/environments/<@environment>/common_vars_for_hcl.json"))
}

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    # You need to update the resource group and storage account here. 
    # You should have created these with the Prepare.ps1 script.
    resource_group_name  = "${local.common_vars.resource_group_name}"
    storage_account_name = "${local.common_vars.state_storage_account_name}"
    container_name       = "tstate"
    key                  = "terraform_layer1.tfstate"
  }
}