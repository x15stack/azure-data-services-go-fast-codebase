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
$output = terragrunt init --terragrunt-config vars/$env:environmentName/terragrunt.hcl -reconfigure 
$output = terragrunt apply -auto-approve --terragrunt-config vars/$env:environmentName/terragrunt.hcl -json #-var synapse_sql_password=$env:TF_VAR_synapse_sql_password  

$warnings = ($output | ConvertFrom-Json -Depth 20) | Where-Object {$_."@level" -eq "warn"}              
$errors = ($output | ConvertFrom-Json -Depth 20) | Where-Object {$_."@level" -eq "error"}              
if($warnings.count -gt 0)
{
    Write-Host "---------------------Terraform Warnings-----------------------------------------------------------"
    foreach($o in $warnings) {Write-Warning ($o."@message" + "; Address:" + $o.diagnostic.address + "; Detail:" + $o.diagnostic.detail)}
    Write-Host "--------------------------------------------------------------------------------------------------"
}
if($errors.count -gt 0)
{
    Write-Host "---------------------Terraform Errors-------------------------------------------------------------"
    foreach($o in $errors) {Write-Error ($o."@message" + "; Address:" + $o.diagnostic.address + "; Detail:" + $o.diagnostic.detail)}
    Write-Host "--------------------------------------------------------------------------------------------------"
}

#Update Values for variables in Environment
$tout_raw = ((az storage blob download -c "tstate" -n "terraform_layer2.tfstate" --account-name $env:TF_VAR_state_storage_account_name --auth-mode login) | ConvertFrom-Json).outputs

$envFolderPath = Convert-Path -Path ($deploymentFolderPath + "./environments/vars/$env:environmentName/")
$varsfile = $envFolderPath + "/common_vars_values.jsonc"
$common_vars_values = Get-Content $varsfile | ConvertFrom-Json -Depth 10
$common_vars_values.ARM_DATALAKE_NAME = $tout_raw.adlsstorage_name.value
$common_vars_values.ARM_KEYVAULT_NAME = $tout_raw.keyvault_name.value
$common_vars_values.ARM_SYNAPSE_WORKSPACE_NAME = $tout_raw.synapse_workspace_name.value
$common_vars_values | Convertto-Json -Depth 10 | Set-Content $varsfile
        
