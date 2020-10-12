using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get Azure VM Resource ID
$rawbody = $Request.RawBody | ConvertFrom-Json
$vmResourceId = $rawbody.data.alertContext.AffectedConfigurationItems
$vm = $vmResourceId.Split('/')

# Create script within function and run on VM
[System.String]$ScriptBlock = {Start-Service w3svc}
$scriptFile = "RunScript.ps1"
Out-File -FilePath $scriptFile -InputObject $ScriptBlock -NoNewline
Invoke-AzVMRunCommand -ResourceGroupName $vm[4] -Name  $vm[8] -CommandId 'RunPowerShellScript' -ScriptPath $scriptFile -AsJob
Remove-Item -Path $scriptFile -Force -ErrorAction SilentlyContinue
