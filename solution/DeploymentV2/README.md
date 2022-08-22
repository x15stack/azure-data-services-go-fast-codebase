
# Developer Installation Instructions
If you want to deploy a once off lockbox for development purposes, the following steps can be used.
## :hammer: Tools & Environment
This solution makes use of development containers feature of GitHub / VsCode. Use the following guidance to get started with dev containers:
- https://code.visualstudio.com/docs/remote/containers

This will save you having to install any of the tooling dependencies and will ensure you have the correct versions of everything installed. 

**:warning: NOTE:** For all scripts, be sure that your working directory is set to the DeploymentV2 folder.

## :green_circle: PART 1. Prepare your Azure enviromnent using Prepare.ps1 script
### :page_with_curl: Pre-requisites
Before you run the **Deploy.ps1** script, make sure you have completed the pre-requisites:
 
 - Run **az login** to login with the Azure CLI
 - Use **az account set** to select the correct subscrption using
 - Ensure you have Contributor or Owner role on the Azure Subscription you are preparing

### :grey_question: What does it do?
The purpose of this script is to prepare your Azure environment ready for the deployment, it will perform the following:
 - Register the Azure Resource Providers
 - Create your Azure Resource Group
 - Create your Azure Storage Account for Terraform state store

### 	:arrow_forward: How do I run this?
Execute the following script file:
```./Prepare.ps1```
When you execute the script it will ask you for a number of inputs:
- **Deployment Environment**: The first step is to select which deployment environment you would like to deploy into. The specifics of each deployment environment are stored within json files located within the [./environments/vars/](./environments/vars/) directory. Within this directory there is a subdirectory for each environment file. The prepare script will gather information and update one of these envionment files. The specific file that will be update depends on which environment you choose at this point.  
![image](https://user-images.githubusercontent.com/11702150/184566506-95b8d705-de58-4c2c-a2e2-5b8dfd855f7b.png)
- **Resource Group Name**: The resource group name to be created. 
![image](https://user-images.githubusercontent.com/11702150/184566884-89671236-cbb6-441d-a6b5-f7390a44b78c.png)
- **Resource Provider Registration**: Select '1' (YES) to ensure that the pre-requisite resource providers have been enabled on your Azure subscription. 
![image](https://user-images.githubusercontent.com/11702150/184566915-ad311bf1-59fc-4c1d-a94c-6d51c3b82101.png)
- **Network Isolation Level**: Select the level of network isolation that you would like for your deployed resources. 'Public' enables public IP access from anywhere. 'Isolated' enables private networking components while allowing tightly controlled public IP based access for a small number of whitelisted IP addresses. This is the most common deployment method which allows a cloud hosted, dynamically provisioned CICD agent to carry out the deployment. 'Private' networking  is an advanced deployment option which will block all public traffic. 
![image](https://user-images.githubusercontent.com/11702150/185845690-e0b64a24-1322-4934-b569-c6faf8f7d153.png)
- **Resource Owner**: Insert the object id of the Azure identity or group that you would like to have ownership of the resource group.  If you are planning to deploy the solution using a CICD agent, it is suggested that you enter the Agent Service Principal's object id here. If you will be deploying from the command line using an interactive session then leave this field blank.
- **SQL Server AAD Admin**: Insert the object id of the Azure identity or group that you would like to be the AAD administrator of any SQL Server instances deployed.  If you are planning to deploy the solution using a CICD agent, then it is suggested that you use an AAD group here. If you will be deploying from the command line using an interactive session then leave this field blank.
- **Press any key to continue**: The script will now evaluate your system to gather required information. A summary of that information will be presented to you (similar to the screen capture below). Review the information and press any key to continue.
![image](https://user-images.githubusercontent.com/11702150/184581848-da28499a-2349-4327-a06b-441353b0de93.png)
- **Automatic Environment File Update**: You will now be asked if you wish to automatically persist the configuration information into the selected environment file. It is recommended that you select 'yes' and allow the script to automatically update the required file. 
![image](https://user-images.githubusercontent.com/11702150/184582043-8490f92e-fe1b-49d1-b548-5061d957a6e2.png)
- **Reset Flags**: During a deployment there may be some manual steps required such as installation of a self hosted integration runtime. In order for the deployment to be aware of the state of these manual steps a number of flags are included in the configuration files. If you select 'yes' at this step the script will reset these flags to their default state. For a new deployment this is recommended. Once you have completed the associated manual steps you can then update the relevant configuration file accordingly.
![image](https://user-images.githubusercontent.com/11702150/184582065-535151c9-ee64-43a8-88c7-b9dbc30bbec1.png)
- **Fast Start Template**: Fast start templates provide a pre-selected combination of features for a deployment. <br/> For most deployments it is recommended to select the "full_deployment' option.
![image](https://user-images.githubusercontent.com/11702150/184582079-43da1f0c-8a05-4ebd-b842-40a7e8e3af35.png)

At the end of the scripts execution the environment details are pre-loaded into environment variables so that you can directly run the ./Deploy.ps1 without doing any manual entry.

## :green_circle: PART 2. Deploy your Lockbox using Deploy.ps1 script
### :page_with_curl: Pre-requisites
Before you run the **Deploy.ps1** script, make sure you have completed the pre-requisites:
- Run the Prepare.ps1 script first. This will prepare your azure subscription for deployment
- Ensure that you have run az login and az account set
- Ensure you have Owner access to the resource group you are planning on deploying into
- Ensure you have the **Application.ReadWrite.OwnedBy** permission with Azure AD to allow you to create and manage AAD app registrations

### :grey_question: What does it do?
This script will:
 - Deploy all infra resources using terraform
 - Approve all private link requests
 - Build and deploy web app
 - Build and deploy function app
 - Build database app and deploy
 - Deploy samples into blob storage
 
### 	:arrow_forward: How do I run this?
Execute the following script file:
```./Deploy.ps1```
You can run this script multiple times if needed.
The configuration for this environment creation is read from the following locations:
- The environment variables created when you ran Prepare.ps1
- The environment configuration file (*where {selected_environment} is the name of the environment that you selected during execution of prepare.ps1):
  -  ```/azure-data-services-go-fast-codebase/solution/DeploymentV2/environment/vars/{selected_environment}/terragrunt.hcl```

## :green_circle: PART 3. Deployment Details
### Deployment Layers - Summary
Layer | Description | Permissions Required when using Service Principal | Permissions Required when using User Principal
| --- | --- | --- | --- |
Terraform Layer Zero | - Deploys the spoke VNET with subnets, dns zones, bastion & a VM for the CICD agent | - Resouce Group Owner <br /> - Blob Contributor on Terraform's State Storage Account | - Resouce Group Owner <br /> - Blob Contributor on Terraform's State Storage Account
Terraform Layer One | - Register AAD Enterprise Applications & Service Principals | - Application.ReadWrite.OwnedBy <br /> - Blob Contributor on Terraform's State Storage Account| - Application Administrator (Role) <br /> - Blob Contributor on Terraform's State Storage Account
Terraform Layer Two | - Core IAC deployment for approx. 70 ADS Go fast resources | - Resource Group Owner <br /> - Blob Contributor on Terraform's State Storage Account| - Resource Group Owner <br /> - Blob Contributor on Terraform's State Storage Account
Terraform Layer Three | - Update AAD Enterprise Applications by granting required roles and permissions to managed service identities created in Layer Two <br /> - Create Private Endpoints for Purview | - Application.ReadWrite.OwnedBy <br /> (Must be same identity as that which was used to run Layer One) <br /> - Blob Contributor on Terraform's State Storage Account | - Application Administrator (Role), <br /> - Network Contributor <br /> - Blob Contributor on Terraform's State Storage Account


Provider | Resources | 
| --- | --- |
azurerm_network_security_group|- app_service_nsg <br/> - bastion_nsg <br/> - plink_nsg <br/> - vm_nsg
azurerm_bastion_host | bastion
azurerm_network_security_rule|app_service_in_deny_all[0]
azurerm_network_security_rule|bastion_inbound_control_plane[0]
azurerm_network_security_rule|bastion_inbound_data_plane[0]
azurerm_network_security_rule|bastion_inbound_internet[0]
azurerm_network_security_rule|bastion_inbound_load_balancer[0]
azurerm_network_security_rule|bastion_outbound_azure[0]
azurerm_network_security_rule|bastion_outbound_bastion_vms[0]
azurerm_network_security_rule|bastion_outbound_dataplane[0]
azurerm_network_security_rule|bastion_outbound_internet[0]
azurerm_network_security_rule|plink_out_deny_all[0]
azurerm_network_security_rule|vm_inbound_bastion[0]

Layer | Description | 
| --- | --- |
data.azurerm_client_config.current
azurerm_bastion_host.bastion[0]


azurerm_private_dns_zone.private_dns_zone_blob[0]
azurerm_private_dns_zone.private_dns_zone_db[0]
azurerm_private_dns_zone.private_dns_zone_dfs[0]
azurerm_private_dns_zone.private_dns_zone_kv[0]
azurerm_private_dns_zone.private_dns_zone_purview[0]
azurerm_private_dns_zone.private_dns_zone_purview_studio[0]
azurerm_private_dns_zone.private_dns_zone_queue[0]
azurerm_private_dns_zone.private_dns_zone_servicebus[0]
azurerm_private_dns_zone.synapse_gateway[0]
azurerm_private_dns_zone.synapse_sql[0]
azurerm_private_dns_zone.synapse_studio[0]
azurerm_private_dns_zone_virtual_network_link.blob[0]
azurerm_private_dns_zone_virtual_network_link.database[0]
azurerm_private_dns_zone_virtual_network_link.dfs[0]
azurerm_private_dns_zone_virtual_network_link.purview[0]
azurerm_private_dns_zone_virtual_network_link.purview_studio[0]
azurerm_private_dns_zone_virtual_network_link.queue[0]
azurerm_private_dns_zone_virtual_network_link.servicebus[0]
azurerm_private_dns_zone_virtual_network_link.synapse_gateway[0]
azurerm_private_dns_zone_virtual_network_link.synapse_sql[0]
azurerm_private_dns_zone_virtual_network_link.synapse_studio[0]
azurerm_private_dns_zone_virtual_network_link.vaultcore[0]
azurerm_public_ip.bastion_pip[0]
azurerm_subnet.app_service_subnet[0]
azurerm_subnet.bastion_subnet[0]
azurerm_subnet.plink_subnet[0]
azurerm_subnet.vm_subnet[0]
azurerm_subnet_network_security_group_association.app_service_nsg[0]
azurerm_subnet_network_security_group_association.bastion_nsg[0]
azurerm_subnet_network_security_group_association.plink_nsg[0]
azurerm_subnet_network_security_group_association.vm_nsg[0]
azurerm_virtual_network.vnet[0]
random_id.rg_deployment_unique
module.naming.random_string.first_letter
module.naming.random_string.main
