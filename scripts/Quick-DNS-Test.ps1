# Quick Function App 2 DNS diagnostic - paste this into the Azure Portal Function Console

# Test DNS resolution for the private storage account
$storageHost = "stgsnefffds2.blob.core.windows.net"

Write-Host "=== DNS Resolution Test ===" -ForegroundColor Yellow
try {
    $dnsResult = Resolve-DnsName -Name $storageHost -ErrorAction Stop
    Write-Host "✅ DNS Resolution successful:" -ForegroundColor Green
    foreach ($result in $dnsResult) {
        Write-Host "  $($result.Name) -> $($result.IPAddress)" -ForegroundColor White
    }
    
    # Check if we got private IP (10.x.x.x range for our VNet)
    $privateIPs = $dnsResult | Where-Object { $_.IPAddress -like "10.*" }
    if ($privateIPs) {
        Write-Host "✅ Private IP address found - DNS working correctly" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Only public IP found - private DNS zone not working" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ DNS Resolution failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Network Connectivity Test ===" -ForegroundColor Yellow
$testUrl = "https://$storageHost"
try {
    $response = Invoke-WebRequest -Uri $testUrl -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Network connectivity successful" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor White
} catch {
    $statusCode = $null
    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
    }
    
    if ($statusCode -eq 400 -or $statusCode -eq 403) {
        Write-Host "✅ Network connectivity OK (got HTTP $statusCode - expected for anonymous access)" -ForegroundColor Green
    } else {
        Write-Host "❌ Network connectivity failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== VNet Configuration Check ===" -ForegroundColor Yellow
Write-Host "WEBSITE_VNET_ROUTE_ALL: $($env:WEBSITE_VNET_ROUTE_ALL)" -ForegroundColor White
Write-Host "FUNCTIONS_WORKER_RUNTIME: $($env:FUNCTIONS_WORKER_RUNTIME)" -ForegroundColor White

Write-Host "`n=== Recommended Next Steps ===" -ForegroundColor Cyan
Write-Host "1. If DNS shows public IP only: Private DNS zone issue" -ForegroundColor White
Write-Host "2. If DNS fails: VNet integration or DNS zone link issue" -ForegroundColor White
Write-Host "3. If network fails: Private endpoint or NSG issue" -ForegroundColor White