# Diagnostic script to check Function App deployment status
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionApp1Name = "amun-fd-func-1",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionApp2Name = "amun-fd-func-2"
)

Write-Host "=== Function App Deployment Diagnostics ===" -ForegroundColor Green

# Check Azure CLI authentication
Write-Host "`n1. Checking Azure CLI authentication..." -ForegroundColor Yellow
try {
    $account = az account show | ConvertFrom-Json
    Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Cyan
} catch {
    Write-Error "❌ Not authenticated with Azure CLI. Run 'az login' first."
    exit 1
}

# Function to check Function App status
function Check-FunctionApp {
    param($AppName)
    
    Write-Host "`nChecking Function App: $AppName" -ForegroundColor Yellow
    
    try {
        # Get Function App details
        $app = az functionapp show --resource-group $ResourceGroupName --name $AppName | ConvertFrom-Json
        
        Write-Host "  ✅ Function App exists" -ForegroundColor Green
        Write-Host "    State: $($app.state)" -ForegroundColor Cyan
        Write-Host "    Runtime: $($app.siteConfig.powerShellVersion)" -ForegroundColor Cyan
        Write-Host "    URL: $($app.defaultHostName)" -ForegroundColor Cyan
        
        # Check if functions are deployed
        $functions = az functionapp function list --resource-group $ResourceGroupName --name $AppName | ConvertFrom-Json
        
        if ($functions.Count -gt 0) {
            Write-Host "  ✅ Functions deployed: $($functions.Count)" -ForegroundColor Green
            foreach ($func in $functions) {
                Write-Host "    - $($func.name)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "  ⚠️  No functions found - deployment may be incomplete" -ForegroundColor Yellow
        }
        
        # Test basic connectivity
        Write-Host "  Testing basic connectivity..." -ForegroundColor Yellow
        try {
            $response = Invoke-WebRequest -Uri "https://$($app.defaultHostName)" -Method Get -TimeoutSec 10
            Write-Host "  ✅ Function App is responding (Status: $($response.StatusCode))" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Function App not responding: $($_.Exception.Message)" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "  ❌ Error checking Function App: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check both Function Apps
Write-Host "`n2. Checking Function Apps..." -ForegroundColor Yellow
Check-FunctionApp -AppName $FunctionApp1Name
Check-FunctionApp -AppName $FunctionApp2Name

# Check storage accounts
Write-Host "`n3. Checking Storage Accounts..." -ForegroundColor Yellow
try {
    $storageAccounts = az storage account list --resource-group $ResourceGroupName | ConvertFrom-Json
    
    foreach ($storage in $storageAccounts) {
        Write-Host "  Storage Account: $($storage.name)" -ForegroundColor Cyan
        Write-Host "    Status: $($storage.provisioningState)" -ForegroundColor Cyan
        Write-Host "    Public Access: $($storage.allowBlobPublicAccess)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "  ❌ Error checking storage accounts: $($_.Exception.Message)" -ForegroundColor Red
}

# Test function endpoints if they exist
Write-Host "`n4. Testing Function Endpoints..." -ForegroundColor Yellow

$endpoints = @(
    "https://$FunctionApp1Name.azurewebsites.net/api/TestStorageConnection",
    "https://$FunctionApp2Name.azurewebsites.net/api/TestPrivateStorageConnection"
)

foreach ($endpoint in $endpoints) {
    Write-Host "  Testing: $endpoint" -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Get -TimeoutSec 30
        Write-Host "  ✅ Response received:" -ForegroundColor Green
        Write-Host "    $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Cyan
    } catch {
        Write-Host "  ❌ Failed to call function: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "    Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Diagnostics Complete ===" -ForegroundColor Green