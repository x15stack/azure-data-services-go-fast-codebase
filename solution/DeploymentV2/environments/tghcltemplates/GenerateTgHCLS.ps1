function GenerateTgHCLS (
    [Parameter(Mandatory = $true)]
    [System.Boolean]$gitDeploy = $false,
    [Parameter(Mandatory = $true)]
    [String]$deploymentFolderPath,
    [Parameter(Mandatory = $false)]
    [String]$PathToReturnTo = ""
) 
{
    $layers = @(0,1,2,3)
    $envlist = (Get-ChildItem -Directory -Path ./../vars | Select-Object -Property Name).Name
    
    foreach ($l in $layers)
    {
        foreach ($e in $envlist)
        {
            $layer = "layer$($l.ToString())"            
            $layer_t = (Get-Content "$layer.hcl" -Raw) 
            $inputs_t = (Get-Content "inputs.hcl" -Raw)
            $template = $layer_t + $inputs_t 
            $template = $template.Replace("<@environment>", $e)
            $template
        }
    }
}