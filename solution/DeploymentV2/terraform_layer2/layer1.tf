# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
    data "terraform_remote_state" "layer1" {
      # The settings here should match the "backend" settings in the
      # configuration that manages the network resources.
      backend = "azurerm"
      
      config = {
        container_name       = "tstate"
        key                  = "terraform_layer1.tfstate"
        resource_group_name  = "gft6"
        storage_account_name = "gf6state"
      }
    }
