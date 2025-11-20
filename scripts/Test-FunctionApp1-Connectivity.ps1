# Function App 1 - Storage Connectivity Test
# Tests connectivity from Function App 1 to Storage Account 1 using IP restrictions
# This script should be deployed as a PowerShell function in sneff-fd-func-1

param($Request, $TriggerMetadata)

# Get storage account details from environment variables
$storageAccountName = $env:STORAGE_ACCOUNT_1_NAME
$storageEndpoint = $env:STORAGE_ACCOUNT_1_ENDPOINT

Write-Host "Starting connectivity test for Function App 1"
Write-Host "Target Storage Account: $storageAccountName"
Write-Host "Target Endpoint: $storageEndpoint"

# Initialize test results
$testResults = @{
    FunctionApp = "sneff-fd-func-1"
    StorageAccount = $storageAccountName
    TestTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
    Tests = @()
}

# Test 1: DNS Resolution
Write-Host "Test 1: DNS Resolution"
try {
    $dnsResult = Resolve-DnsName "$storageAccountName.blob.core.windows.net" -ErrorAction Stop
    $testResults.Tests += @{
        TestName = "DNS Resolution"
        Status = "PASS"
        Details = "Resolved to: $($dnsResult.IPAddress -join ', ')"
    }
    Write-Host "✅ DNS Resolution: PASS - Resolved to: $($dnsResult.IPAddress -join ', ')"
} catch {
    $testResults.Tests += @{
        TestName = "DNS Resolution"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ DNS Resolution: FAIL - $($_.Exception.Message)"
}

# Test 2: HTTPS Connectivity
Write-Host "Test 2: HTTPS Connectivity"
try {
    $response = Invoke-WebRequest -Uri $storageEndpoint -Method HEAD -ErrorAction Stop -TimeoutSec 30
    $testResults.Tests += @{
        TestName = "HTTPS Connectivity"
        Status = "PASS"
        Details = "HTTP Status: $($response.StatusCode)"
    }
    Write-Host "✅ HTTPS Connectivity: PASS - Status: $($response.StatusCode)"
} catch {
    $testResults.Tests += @{
        TestName = "HTTPS Connectivity"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ HTTPS Connectivity: FAIL - $($_.Exception.Message)"
}

# Test 3: Storage Account Access (using Managed Identity if available)
Write-Host "Test 3: Storage Account Access"
try {
    # Try to get account properties to test access
    $uri = "https://$storageAccountName.blob.core.windows.net/?restype=service&comp=properties"
    $headers = @{}
    
    # Get access token using managed identity
    try {
        $tokenResponse = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/' -Headers @{Metadata="true"} -ErrorAction SilentlyContinue
        if ($tokenResponse.access_token) {
            $headers["Authorization"] = "Bearer $($tokenResponse.access_token)"
        }
    } catch {
        Write-Host "No managed identity token available, testing without authentication"
    }
    
    $storageResponse = Invoke-WebRequest -Uri $uri -Headers $headers -ErrorAction Stop -TimeoutSec 30
    $testResults.Tests += @{
        TestName = "Storage Account Access"
        Status = "PASS"
        Details = "Successfully accessed storage properties"
    }
    Write-Host "✅ Storage Account Access: PASS"
} catch {
    $testResults.Tests += @{
        TestName = "Storage Account Access"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ Storage Account Access: FAIL - $($_.Exception.Message)"
}

# Test 4: Network Path Analysis
Write-Host "Test 4: Network Path Analysis"
try {
    # Get the function app's outbound IP
    $outboundIPs = $env:WEBSITE_OUTBOUND_IP_ADDRESSES
    if ($outboundIPs) {
        $testResults.Tests += @{
            TestName = "Network Path Analysis"
            Status = "INFO"
            Details = "Function App Outbound IPs: $outboundIPs"
        }
        Write-Host "ℹ️ Function App Outbound IPs: $outboundIPs"
    } else {
        $testResults.Tests += @{
            TestName = "Network Path Analysis"
            Status = "INFO"
            Details = "Outbound IP information not available"
        }
        Write-Host "ℹ️ Outbound IP information not available"
    }
} catch {
    $testResults.Tests += @{
        TestName = "Network Path Analysis"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ Network Path Analysis: FAIL - $($_.Exception.Message)"
}

# Summary
$passedTests = ($testResults.Tests | Where-Object { $_.Status -eq "PASS" }).Count
$totalTests = ($testResults.Tests | Where-Object { $_.Status -in @("PASS", "FAIL") }).Count

Write-Host "`n=== TEST SUMMARY ==="
Write-Host "Function App: sneff-fd-func-1"
Write-Host "Target Storage: $storageAccountName (IP-restricted access)"
Write-Host "Passed: $passedTests/$totalTests tests"
Write-Host "Connection Method: IP Allowlist"

# Return results for HTTP response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $testResults | ConvertTo-Json -Depth 3
    Headers = @{
        'Content-Type' = 'application/json'
    }
})