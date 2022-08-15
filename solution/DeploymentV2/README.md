
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
- **Resource Owner**: Insert the object id of the Azure identity or group that you would like to have ownership of the resource group.  If you are planning to deploy the solution using a CICD agent, it is suggested that you enter the Agent Service Principal's object id here. If you will be deploying from the command line using an interactive session then leave this field blank.
- **SQL Server AAD Admin**: Insert the object id of the Azure identity or group that you would like to be the AAD administrator of any SQL Server instances deployed.  If you are planning to deploy the solution using a CICD agent, then it is suggested that you use an AAD group here. If you will be deploying from the command line using an interactive session then leave this field blank.

 
At the end of the execution, you will be provided the details of what was performed as well as the resource & subscription details.
These are pre-loaded into environment variables so that you can directly run the ./Deploy.ps1 without doing any manual entry.

To save you having to do more work later, I recommend that you copy them down and update the values directly into the following file:

 ```/azure-data-services-go-fast-codebase/solution/DeploymentV2/terraform/vars/local/terragrunt.hcl```

 This file is used by the ./Deploy.ps1 script by default and will be used if no enviroment vars are available

## :green_circle: PART 2. Deploy your Lockbox using Deploy.ps1 script
### :page_with_curl: Pre-requisites
Before you run the **Deploy.ps1** script, make sure you have completed the pre-requisites:
- Run the Prepare.ps1 script first. This will prepare your azure subscription for deployment
- Ensure that you have run az login and az account set
- Ensure you have Owner access to the resource group you are planning on deploying into
- Ensure you have the **Application.ReadWrite.OwnedBy** permission with Azure AD to allow you to create and manage AAD app registrations

### :grey_question: What does it do?
This script will:
 - Deploy all infra resources using terra
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
- The environment configuration file:
  -  ```/azure-data-services-go-fast-codebase/solution/DeploymentV2/terraform/vars/local/terragrunt.hcl```

Layer | Description | Permissions Required when using Service Principal | Permissions Required when using User Principal
| --- | --- | --- | --- |
Terraform Layer One | - Register AAD Enterprise Applications & Service Principals | - Application.ReadWrite.OwnedBy | - Application Administrator (Role)
Terraform Layer Two | - Core IAC deployment for approx. 70 ADS Go fast resources | - Resource Group Owner | - Resource Group Owner
Terraform Layer Three | - Update AAD Enterprise Applications by granting required roles and permissions to managed service identities created in Layer Two <br /> - Create Private Endpoints for Purview | - Application.ReadWrite.OwnedBy <br /> (Must be same identity as that which was used to run Layer One) | - Application Administrator (Role), <br /> - Network Contributor 
