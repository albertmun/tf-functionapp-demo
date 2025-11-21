using namespace System.Net

param($Request, $TriggerMetadata)

# Minimal test of the original function logic without DNS calls
try {
    $storageAccountName = $env:STORAGE_ACCOUNT_2_NAME
    $storageEndpoint = $env:STORAGE_ACCOUNT_2_ENDPOINT
    
    $testResult = @{
        FunctionApp = "amun-fd-func-2"
        StorageAccount = $storageAccountName
        StorageEndpoint = $storageEndpoint
        AccessMethod = "Testing without DNS calls"
        VNetIntegration = $env:WEBSITE_VNET_ROUTE_ALL
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        Status = "TESTING"
    }
    
    # Test just the HTTP request part (skip DNS resolution)
    try {
        Write-Host "Testing HTTP request to: $storageEndpoint"
        $response = Invoke-WebRequest -Uri $storageEndpoint -Method Head -TimeoutSec 10
        $testResult.Status = "SUCCESS"
        $testResult.StatusCode = $response.StatusCode
        $testResult.Message = "Storage account accessible"
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        if ($statusCode -eq 400 -or $statusCode -eq 403) {
            $testResult.Status = "NETWORK_SUCCESS"
            $testResult.StatusCode = $statusCode
            $testResult.Message = "Storage account reachable (auth error is expected)"
        } else {
            $testResult.Status = "FAILED"
            $testResult.Error = $_.Exception.Message
            $testResult.StatusCode = $statusCode
        }
    }
    
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
        Type = $_.Exception.GetType().Name
        StackTrace = $_.ScriptStackTrace
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($errorResult | ConvertTo-Json -Depth 3)
    })
}