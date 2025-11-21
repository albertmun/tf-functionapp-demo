# Test APIM API Integration with Function App 2
# This script tests all Function App 2 endpoints through APIM

param(
    [Parameter(Mandatory=$false)]
    [string]$ApimName = "apim-fd-public-amun2",
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionKey = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

$ErrorActionPreference = "Continue"

# Get APIM gateway URL
$apimUrl = "https://$ApimName.azure-api.net/funcapp2"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing APIM API for Function App 2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "APIM URL: $apimUrl" -ForegroundColor Yellow
Write-Host ""

# Setup headers
$headers = @{
    "Content-Type" = "application/json"
}

if ($SubscriptionKey) {
    $headers["Ocp-Apim-Subscription-Key"] = $SubscriptionKey
    Write-Host "Using subscription key authentication" -ForegroundColor Green
} else {
    Write-Host "No subscription key provided (assuming open access)" -ForegroundColor Yellow
}

Write-Host ""

# Define endpoints to test
$endpoints = @(
    @{
        Name = "Health Check"
        Path = "/HealthCheck"
        Description = "Verifies Function App 2 is running"
    },
    @{
        Name = "Simple Test"
        Path = "/SimpleTest"
        Description = "Basic connectivity test"
    },
    @{
        Name = "Network Diagnostics"
        Path = "/NetworkDiagnostics"
        Description = "Network configuration details"
    },
    @{
        Name = "Test Private Storage"
        Path = "/TestPrivateStorageConnection"
        Description = "Tests private endpoint storage access"
    },
    @{
        Name = "Test Storage Simple"
        Path = "/TestStorageSimple"
        Description = "Simple storage connectivity test"
    }
)

$results = @()

foreach ($endpoint in $endpoints) {
    $url = "$apimUrl$($endpoint.Path)"
    
    Write-Host "Testing: $($endpoint.Name)" -ForegroundColor Cyan
    Write-Host "  URL: $url" -ForegroundColor Gray
    Write-Host "  Description: $($endpoint.Description)" -ForegroundColor Gray
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers -TimeoutSec 30
        
        $stopwatch.Stop()
        $elapsed = $stopwatch.ElapsedMilliseconds
        
        Write-Host "  ✓ SUCCESS" -ForegroundColor Green
        Write-Host "  Response Time: $elapsed ms" -ForegroundColor Gray
        
        if ($ShowDetails) {
            Write-Host "  Response:" -ForegroundColor Gray
            $response | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor DarkGray
        }
        
        $results += [PSCustomObject]@{
            Endpoint = $endpoint.Name
            Status = "Success"
            ResponseTime = $elapsed
            Error = $null
        }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        
        Write-Host "  ✗ FAILED" -ForegroundColor Red
        Write-Host "  Error: $statusCode - $statusDescription" -ForegroundColor Red
        
        if ($ShowDetails) {
            Write-Host "  Details: $($_.Exception.Message)" -ForegroundColor DarkRed
        }
        
        $results += [PSCustomObject]@{
            Endpoint = $endpoint.Name
            Status = "Failed"
            ResponseTime = $null
            Error = "$statusCode - $statusDescription"
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$results | Format-Table -AutoSize

$successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "Failed" }).Count
$totalCount = $results.Count

Write-Host "`nTotal Tests: $totalCount" -ForegroundColor White
Write-Host "Passed: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red

if ($failCount -gt 0) {
    Write-Host "`nTroubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "- Verify Function App 2 is running" -ForegroundColor Gray
    Write-Host "- Check IP restrictions allow APIM's public IP" -ForegroundColor Gray
    Write-Host "- Confirm APIM API and operations are deployed" -ForegroundColor Gray
    Write-Host "- Check Azure Portal for Function App errors" -ForegroundColor Gray
    exit 1
} else {
    Write-Host "`n✓ All tests passed!" -ForegroundColor Green
    exit 0
}
