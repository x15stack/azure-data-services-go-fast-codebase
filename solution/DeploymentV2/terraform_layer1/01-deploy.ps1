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
Write-Host "Starting Terraform Deployment- Layer 1"
$output = terragrunt init --terragrunt-config vars/$env:environmentName/terragrunt.hcl -reconfigure
$output = terragrunt apply -auto-approve --terragrunt-config vars/$env:environmentName/terragrunt.hcl -json 

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