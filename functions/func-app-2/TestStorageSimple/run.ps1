using namespace System.Net

param($Request, $TriggerMetadata)

Write-Host "Function App 2 - Testing Storage Connection (Simplified Version)"

try {
    # Get storage account details from environment variables
    $storageAccountName = $env:STORAGE_ACCOUNT_2_NAME
    $storageEndpoint = $env:STORAGE_ACCOUNT_2_ENDPOINT
    
    $testResult = @{
        FunctionApp = "sneff-fd-func-2"
        StorageAccount = $storageAccountName
        StorageEndpoint = $storageEndpoint
        AccessMethod = "Public Storage Test"
        VNetIntegration = $env:WEBSITE_VNET_ROUTE_ALL
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    Write-Host "Testing connectivity to: $storageEndpoint"
    
    # Test storage connectivity with better error handling
    try {
        $response = Invoke-WebRequest -Uri $storageEndpoint -Method Head -TimeoutSec 10 -ErrorAction Stop
        $testResult.Status = "SUCCESS"
        $testResult.StatusCode = $response.StatusCode
        $testResult.Message = "Storage account accessible"
        
        Write-Host "Success: HTTP $($response.StatusCode)"
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        
        Write-Host "HTTP Error: $statusCode - $($_.Exception.Message)"
        
        if ($statusCode -eq 400 -or $statusCode -eq 403) {
            # Expected for anonymous HEAD requests to storage
            $testResult.Status = "SUCCESS"
            $testResult.StatusCode = $statusCode
            $testResult.Message = "Storage reachable (HTTP $statusCode expected for anonymous access)"
        } 
        elseif ($statusCode -eq 404) {
            $testResult.Status = "SUCCESS" 
            $testResult.StatusCode = $statusCode
            $testResult.Message = "Storage reachable (HTTP 404 - endpoint accessible)"
        }
        else {
            $testResult.Status = "FAILED"
            $testResult.StatusCode = $statusCode
            $testResult.Error = $_.Exception.Message
            $testResult.Message = "Storage connectivity failed"
        }
    }
    
    # Add DNS resolution test (simplified)
    try {
        $storageHost = ([System.Uri]$storageEndpoint).Host
        $dnsAddresses = [System.Net.Dns]::GetHostAddresses($storageHost)
        $testResult.DNS = ($dnsAddresses | ForEach-Object { $_.ToString() }) -join ", "
        Write-Host "DNS Resolution: $($testResult.DNS)"
    } catch {
        $testResult.DNS = "DNS failed: $($_.Exception.Message)"
        Write-Host "DNS Error: $($_.Exception.Message)"
    }
    
    Write-Host "Test completed successfully"
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($testResult | ConvertTo-Json -Depth 3)
    })
}
catch {
    Write-Host "Function error: $($_.Exception.Message)"
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
    
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