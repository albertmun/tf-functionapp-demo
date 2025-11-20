# Quick script to add IP restrictions to Storage Account 1 
# Run this after getting the Function App's outbound IP address

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "tf-demo",
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName = "stgsnefffds1",
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppIP = "40.64.83.186"  # From the function output
)

Write-Host "Adding IP restriction to Storage Account: $StorageAccountName" -ForegroundColor Green
Write-Host "Allowing IP: $FunctionAppIP" -ForegroundColor Cyan

try {
    # Update storage account network rules to deny by default and allow specific IP
    az storage account network-rule add `
        --resource-group $ResourceGroupName `
        --account-name $StorageAccountName `
        --ip-address $FunctionAppIP
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Added IP rule for $FunctionAppIP" -ForegroundColor Green
    }
    
    # Set default action to Deny
    az storage account update `
        --resource-group $ResourceGroupName `
        --name $StorageAccountName `
        --default-action Deny `
        --bypass AzureServices
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Set default action to Deny" -ForegroundColor Green
        Write-Host "🔒 Storage Account now uses IP restrictions!" -ForegroundColor Yellow
    } else {
        Write-Error "❌ Failed to update default action"
    }
    
} catch {
    Write-Error "Failed to update storage account: $($_.Exception.Message)"
}

Write-Host "`nStorage Account network rules updated. Test the function again!" -ForegroundColor Green