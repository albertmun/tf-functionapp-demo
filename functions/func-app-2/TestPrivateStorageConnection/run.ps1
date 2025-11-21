using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Function App 2 - Testing Storage Account 2 Connection via Private Endpoint"

try {
    # Get storage account details from environment variables
    $storageAccountName = $env:STORAGE_ACCOUNT_2_NAME
    $storageEndpoint = $env:STORAGE_ACCOUNT_2_ENDPOINT
    
    # Test private endpoint connectivity
    $testResult = @{
        FunctionApp = "amun-fd-func-2"
        StorageAccount = $storageAccountName
        StorageEndpoint = $storageEndpoint
        AccessMethod = "VNet Integration + Private Endpoint"
        VNetIntegration = $env:WEBSITE_VNET_ROUTE_ALL
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    # Try to access storage endpoint via private endpoint (basic connectivity test)
    try {
        # Simple HEAD request to test network connectivity via private endpoint
        $response = Invoke-WebRequest -Uri $storageEndpoint -Method Head -TimeoutSec 10
        $testResult.Status = "SUCCESS"
        $testResult.StatusCode = $response.StatusCode
        $testResult.Message = "Storage account accessible via private endpoint"
        
        # Try to resolve the private DNS name using .NET instead of PowerShell cmdlet
        try {
            $storageHost = ([System.Uri]$storageEndpoint).Host
            $dnsResult = [System.Net.Dns]::GetHostAddresses($storageHost)
            $testResult.PrivateDNS = ($dnsResult | ForEach-Object { $_.ToString() }) -join ", " 
        } catch {
            $testResult.PrivateDNS = "DNS resolution failed: $($_.Exception.Message)"
        }
    }
    catch {
        # Check the specific error to determine if it's network vs auth
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        if ($statusCode -eq 400 -or $statusCode -eq 403) {
            # 400/403 means we reached the storage account via private endpoint (network OK)
            $testResult.Status = "NETWORK_SUCCESS"
            $testResult.StatusCode = $statusCode
            $testResult.Message = "Storage account reachable via private endpoint (auth error is expected for anonymous access)"
            
            # Try to resolve the private DNS name using .NET methods
            try {
                $storageHost = ([System.Uri]$storageEndpoint).Host
                $dnsAddresses = [System.Net.Dns]::GetHostAddresses($storageHost)
                $testResult.PrivateDNS = ($dnsAddresses | ForEach-Object { $_.ToString() }) -join ", " 
            } catch {
                $testResult.PrivateDNS = "DNS resolution failed: $($_.Exception.Message)"
            }
        }
        elseif ($_.Exception.Message -match "timeout|refused|unreachable|network") {
            # Network connectivity issues - likely VNet/private endpoint problems
            $testResult.Status = "BLOCKED"
            $testResult.Error = $_.Exception.Message
            $testResult.Message = "Storage account not reachable - check VNet integration and private endpoint configuration"
        }
        else {
            # Other errors
            $testResult.Status = "FAILED"
            $testResult.Error = $_.Exception.Message
            $testResult.Message = "Unknown connectivity issue via private endpoint"
        }
    }
    
    # Return results
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($testResult | ConvertTo-Json -Depth 3)
    })
}
catch {
    $errorResult = @{
        Status = "ERROR"
        Error = $_.Exception.Message
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($errorResult | ConvertTo-Json -Depth 3)
    })
}