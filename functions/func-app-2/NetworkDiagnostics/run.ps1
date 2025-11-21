using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Function App 2 - Comprehensive Network Diagnostics"

try {
    # Get environment details
    $storageAccountName = $env:STORAGE_ACCOUNT_2_NAME
    $storageEndpoint = $env:STORAGE_ACCOUNT_2_ENDPOINT
    $vnetRouteAll = $env:WEBSITE_VNET_ROUTE_ALL
    
    $diagnostics = @{
        FunctionApp = "amun-fd-func-2"
        StorageAccount = $storageAccountName
        StorageEndpoint = $storageEndpoint
        VNetRouteAll = $vnetRouteAll
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        Tests = @{}
    }
    
    Write-Host "Starting network diagnostics..."
    
    # Test 1: DNS Resolution using .NET methods (PowerShell Resolve-DnsName not available in Azure Functions)
    Write-Host "Test 1: DNS Resolution"
    try {
        $storageHost = ([System.Uri]$storageEndpoint).Host
        $dnsResult = [System.Net.Dns]::GetHostAddresses($storageHost)
        
        $ipAddresses = $dnsResult | ForEach-Object { $_.ToString() }
        $diagnostics.Tests.DNS = @{
            Status = "SUCCESS"
            Host = $storageHost
            IPs = $ipAddresses -join ", "
            Type = if ($ipAddresses -match "^10\.") { "PRIVATE" } else { "PUBLIC" }
        }
        Write-Host "✅ DNS Resolution: $($diagnostics.Tests.DNS.IPs) ($($diagnostics.Tests.DNS.Type))"
    }
    catch {
        $diagnostics.Tests.DNS = @{
            Status = "FAILED"
            Host = $storageHost
            Error = $_.Exception.Message
        }
        Write-Host "❌ DNS Resolution failed: $($_.Exception.Message)"
    }
    
    # Test 2: Basic Network Connectivity (ping-like test)
    Write-Host "Test 2: Basic HTTP Connectivity"
    try {
        $response = Invoke-WebRequest -Uri $storageEndpoint -Method Head -TimeoutSec 5 -ErrorAction Stop
        $diagnostics.Tests.NetworkConnectivity = @{
            Status = "SUCCESS"
            StatusCode = $response.StatusCode
            Message = "HTTP connectivity successful"
        }
        Write-Host "✅ Network connectivity: HTTP $($response.StatusCode)"
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        if ($statusCode -in @(400, 403, 404)) {
            $diagnostics.Tests.NetworkConnectivity = @{
                Status = "SUCCESS"
                StatusCode = $statusCode
                Message = "Network reachable (HTTP $statusCode is expected for storage endpoint HEAD request)"
            }
            Write-Host "✅ Network connectivity: HTTP $statusCode (expected)"
        } else {
            $diagnostics.Tests.NetworkConnectivity = @{
                Status = "FAILED"
                Error = $_.Exception.Message
                StatusCode = $statusCode
            }
            Write-Host "❌ Network connectivity failed: $($_.Exception.Message)"
        }
    }
    
    # Test 3: Internet Connectivity (test access to a known public endpoint)
    Write-Host "Test 3: General Internet Connectivity"
    try {
        $response = Invoke-WebRequest -Uri "https://www.microsoft.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
        $diagnostics.Tests.InternetConnectivity = @{
            Status = "SUCCESS"
            StatusCode = $response.StatusCode
            Message = "Internet connectivity working"
        }
        Write-Host "✅ Internet connectivity: Working"
    }
    catch {
        $diagnostics.Tests.InternetConnectivity = @{
            Status = "FAILED"
            Error = $_.Exception.Message
            Message = "Internet connectivity blocked - likely VNet routing issue"
        }
        Write-Host "❌ Internet connectivity failed: $($_.Exception.Message)"
    }
    
    # Test 4: Environment Variables Check
    Write-Host "Test 4: Environment Configuration"
    $envVars = @{
        "WEBSITE_VNET_ROUTE_ALL" = $env:WEBSITE_VNET_ROUTE_ALL
        "STORAGE_ACCOUNT_2_NAME" = $env:STORAGE_ACCOUNT_2_NAME
        "STORAGE_ACCOUNT_2_ENDPOINT" = $env:STORAGE_ACCOUNT_2_ENDPOINT
        "FUNCTIONS_WORKER_RUNTIME" = $env:FUNCTIONS_WORKER_RUNTIME
    }
    
    $diagnostics.Tests.Environment = @{
        Status = "INFO"
        Variables = $envVars
    }
    
    foreach ($var in $envVars.GetEnumerator()) {
        if ($var.Value) {
            Write-Host "✅ $($var.Name): $($var.Value)"
        } else {
            Write-Host "❌ $($var.Name): NOT SET"
        }
    }
    
    # Summary
    Write-Host "`n=== DIAGNOSIS SUMMARY ==="
    
    if ($diagnostics.Tests.InternetConnectivity.Status -eq "FAILED") {
        $diagnostics.Diagnosis = "VNet routing issue - internet access blocked"
        $diagnostics.Recommendation = "Check VNet/subnet configuration, NSG rules, or disable WEBSITE_VNET_ROUTE_ALL for public storage access"
    }
    elseif ($diagnostics.Tests.DNS.Status -eq "FAILED") {
        $diagnostics.Diagnosis = "DNS resolution failure"
        $diagnostics.Recommendation = "Check private DNS zone configuration and VNet links"
    }
    elseif ($diagnostics.Tests.NetworkConnectivity.Status -eq "FAILED") {
        $diagnostics.Diagnosis = "Network connectivity issue to storage"
        $diagnostics.Recommendation = "Check private endpoint configuration or firewall rules"
    }
    else {
        $diagnostics.Diagnosis = "Network connectivity appears to be working"
        $diagnostics.Recommendation = "Check application-level issues or authentication"
    }
    
    Write-Host "Diagnosis: $($diagnostics.Diagnosis)"
    Write-Host "Recommendation: $($diagnostics.Recommendation)"
    
    # Return results
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($diagnostics | ConvertTo-Json -Depth 4)
    })
}
catch {
    $errorResult = @{
        Status = "ERROR"
        Error = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    Write-Host "❌ Function execution error: $($_.Exception.Message)"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($errorResult | ConvertTo-Json -Depth 3)
    })
}