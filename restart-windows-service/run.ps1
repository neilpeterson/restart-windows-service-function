# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Get Azure VM Resource ID
$rawbody = $Request.RawBody | ConvertFrom-Json
$vmResourceId = $rawbody.data.alertContext.AffectedConfigurationItems

# Extract values from VM Resource ID
$vm = $vmResourceId.Split('/')
$resourceGroupName = $vm[4]
$vmName = $vm[8]
$subscriptionId = $vm[2]

# Get function identity credentials
$tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=https%3A%2F%2Fmanagement.azure.com%2F&api-version=2019-08-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $tokenAuthURI
$accessToken = $tokenResponse.access_token

# Run Command API
$RunCommandApiUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$VMName/runCommand?api-version=2020-06-01"

# Run Command API request which include the commands to be run
$Body = @{
    commandId = "RunPowerShellScript"
    script = @("Start-Service w3svc")
}

# Invoke Run Command against VM
# I've found the REST API more reliable than the PowerShell module
Invoke-RestMethod -Method Post -Uri $RunCommandApiUri -Headers @{Authorization ="Bearer $accessToken"} -Body ($Body | ConvertTo-Json) -ContentType 'application/json'
