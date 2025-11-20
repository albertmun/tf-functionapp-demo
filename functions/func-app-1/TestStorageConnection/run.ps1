using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Function App 1 - Testing Storage Account 1 Connection via IP Restrictions"

try {
    # Get storage account details from environment variables
    $storageAccountName = $env:STORAGE_ACCOUNT_1_NAME
    $storageEndpoint = $env:STORAGE_ACCOUNT_1_ENDPOINT
    
    # Get Function App's current outbound IP
    $outboundIPs = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json").ip
    
    # Test storage connectivity
    $testResult = @{
        FunctionApp = "sneff-fd-func-1"
        StorageAccount = $storageAccountName
        StorageEndpoint = $storageEndpoint
        AccessMethod = "IP Restrictions"
        FunctionOutboundIP = $outboundIPs
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    # Try to access storage endpoint (basic connectivity test)
    try {
        # Simple HEAD request to test network connectivity
        # This will return 400 if accessible (expected for anonymous access)
        # or network error if blocked by IP restrictions
        $response = Invoke-WebRequest -Uri $storageEndpoint -Method Head -TimeoutSec 10
        $testResult.Status = "SUCCESS"
        $testResult.StatusCode = $response.StatusCode
        $testResult.Message = "Storage account accessible via IP restrictions"
    }
    catch {
        # Check the specific error to determine if it's network vs auth
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        if ($statusCode -eq 400 -or $statusCode -eq 403) {
            # 400/403 means we reached the storage account (network OK) but auth failed (expected)
            $testResult.Status = "NETWORK_SUCCESS"
            $testResult.StatusCode = $statusCode
            $testResult.Message = "Storage account reachable via IP restrictions (auth error is expected for anonymous access)"
        }
        elseif ($_.Exception.Message -match "timeout|refused|unreachable|network") {
            # Network connectivity issues - likely blocked by IP restrictions
            $testResult.Status = "BLOCKED"
            $testResult.Error = $_.Exception.Message
            $testResult.Message = "Storage account blocked by IP restrictions - Function IP not in allowed list"
        }
        else {
            # Other errors
            $testResult.Status = "FAILED"
            $testResult.Error = $_.Exception.Message
            $testResult.Message = "Unknown connectivity issue"
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