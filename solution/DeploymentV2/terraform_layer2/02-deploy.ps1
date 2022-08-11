#----------------------------------------------------------------------------------------------------------------
# You must be logged into the Azure CLI to run this script
#----------------------------------------------------------------------------------------------------------------
# This script will: 
# - Deploy the required AAD objects (Application Registrations etc)
# 
# This is intended for creating a once off deployment from your development machine. You should setup the
# GitHub actions for your long term prod/non-prod environments
#
# Intructions
# - Ensure that you have run the Prepare.ps1 script first. This will prepare your azure subscription for deployment
# - Ensure that you have run az login and az account set
# - Ensure you have Contributor Access to the subscription you are deploying to. 
# - Ensure you have Application.ReadWrite.OwnedBy on the Azure AD. 
# - Run this script
# 
# You can run this script multiple times if needed.
# 
#----------------------------------------------------------------------------------------------------------------
param (
    [Parameter(Mandatory=$false)]
    [string]$FeatureTemplate=""
)

#------------------------------------------------------------------------------------------------------------
# Module Imports #Mandatory
#------------------------------------------------------------------------------------------------------------
import-Module ./../pwshmodules/GatherOutputsFromTerraform.psm1 -force
import-Module ./../pwshmodules/Deploy_0_Prep.psm1 -force
#------------------------------------------------------------------------------------------------------------
# Preparation #Mandatory
#------------------------------------------------------------------------------------------------------------
$PathToReturnTo = (Get-Location).Path
$deploymentFolderPath = Convert-Path -Path ((Get-Location).tostring() + './../')
$gitDeploy = ([System.Environment]::GetEnvironmentVariable('gitDeploy')  -eq 'true')
$skipTerraformDeployment = ([System.Environment]::GetEnvironmentVariable('skipTerraformDeployment')  -eq 'true')
$ipaddress = $env:TF_VAR_ip_address
$ipaddress2 = $env:TF_VAR_ip_address2

PrepareDeployment -gitDeploy $gitDeploy -deploymentFolderPath $deploymentFolderPath -FeatureTemplate $FeatureTemplate -PathToReturnTo $PathToReturnTo

#------------------------------------------------------------------------------------------------------------
# Main Terraform - Layer1
#------------------------------------------------------------------------------------------------------------
Write-Host "Starting Terraform Deployment- Layer 2"
terragrunt init --terragrunt-config vars/$env:environmentName/terragrunt.hcl -reconfigure
terragrunt apply -auto-approve --terragrunt-config vars/$env:environmentName/terragrunt.hcl

#------------------------------------------------------------------------------------------------------------
# Auto Populate common vars with deployed keyvault / storage / synapse workspace names
#------------------------------------------------------------------------------------------------------------

Write-Host "Writing Deployed resource names to common vars"

$common_vars_values = Get-Content ../environments/vars/$env:environmentName/common_vars_values.jsonc | ConvertFrom-Json -Depth 10

$output = terraform output --json | ConvertFrom-Json -Depth 10

$common_vars_values.ARM_SYNAPSE_WORKSPACE_NAME = $output.synapse_workspace_name.value
$common_vars_values.ARM_KEYVAULT_NAME = $output.keyvault_name.value
$common_vars_values.ARM_DATALAKE_NAME = $output.adlsstorage_name.value

$common_vars_values | Convertto-Json -Depth 10 | Set-Content ../environments/vars/$env:environmentName/common_vars_values.jsonc
