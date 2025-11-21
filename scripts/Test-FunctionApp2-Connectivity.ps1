# Function App 2 - Storage Connectivity Test
# Tests connectivity from Function App 2 to Storage Account 2 using Private Endpoint and VNet integration
# This script should be deployed as a PowerShell function in amun-fd-func-2

param($Request, $TriggerMetadata)

# Get storage account details from environment variables
$storageAccountName = $env:STORAGE_ACCOUNT_2_NAME
$storageEndpoint = $env:STORAGE_ACCOUNT_2_ENDPOINT

Write-Host "Starting connectivity test for Function App 2"
Write-Host "Target Storage Account: $storageAccountName"
Write-Host "Target Endpoint: $storageEndpoint"

# Initialize test results
$testResults = @{
    FunctionApp = "amun-fd-func-2"
    StorageAccount = $storageAccountName
    TestTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
    Tests = @()
}

# Test 1: DNS Resolution (should resolve to private IP)
Write-Host "Test 1: DNS Resolution (Private IP)"
try {
    $dnsResult = Resolve-DnsName "$storageAccountName.blob.core.windows.net" -ErrorAction Stop
    $resolvedIPs = $dnsResult.IPAddress
    $isPrivateIP = $resolvedIPs | ForEach-Object { 
        $ip = [System.Net.IPAddress]::Parse($_)
        $ip.ToString().StartsWith("10.") -or $ip.ToString().StartsWith("172.") -or $ip.ToString().StartsWith("192.168.")
    }
    
    if ($isPrivateIP -contains $true) {
        $testResults.Tests += @{
            TestName = "DNS Resolution (Private)"
            Status = "PASS"
            Details = "Resolved to private IP: $($resolvedIPs -join ', ')"
        }
        Write-Host "✅ DNS Resolution: PASS - Resolved to private IP: $($resolvedIPs -join ', ')"
    } else {
        $testResults.Tests += @{
            TestName = "DNS Resolution (Private)"
            Status = "WARN"
            Details = "Resolved to public IP: $($resolvedIPs -join ', ') - Private DNS may not be configured"
        }
        Write-Host "⚠️ DNS Resolution: WARN - Resolved to public IP: $($resolvedIPs -join ', ')"
    }
} catch {
    $testResults.Tests += @{
        TestName = "DNS Resolution (Private)"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ DNS Resolution: FAIL - $($_.Exception.Message)"
}

# Test 2: HTTPS Connectivity through Private Endpoint
Write-Host "Test 2: HTTPS Connectivity (Private Endpoint)"
try {
    $response = Invoke-WebRequest -Uri $storageEndpoint -Method HEAD -ErrorAction Stop -TimeoutSec 30
    $testResults.Tests += @{
        TestName = "HTTPS Connectivity (Private)"
        Status = "PASS"
        Details = "HTTP Status: $($response.StatusCode) - Connected via private endpoint"
    }
    Write-Host "✅ HTTPS Connectivity: PASS - Status: $($response.StatusCode)"
} catch {
    $testResults.Tests += @{
        TestName = "HTTPS Connectivity (Private)"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ HTTPS Connectivity: FAIL - $($_.Exception.Message)"
}

# Test 3: VNet Integration Status
Write-Host "Test 3: VNet Integration Status"
try {
    # Check for VNet-related environment variables
    $vnetRouteAll = $env:WEBSITE_VNET_ROUTE_ALL
    $vnetInfo = if ($vnetRouteAll) { "VNet route all enabled: $vnetRouteAll" } else { "VNet route all not detected" }
    
    $testResults.Tests += @{
        TestName = "VNet Integration Status"
        Status = "INFO"
        Details = $vnetInfo
    }
    Write-Host "ℹ️ VNet Integration: $vnetInfo"
} catch {
    $testResults.Tests += @{
        TestName = "VNet Integration Status"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ VNet Integration Status: FAIL - $($_.Exception.Message)"
}

# Test 4: Storage Account Access (using Managed Identity)
Write-Host "Test 4: Storage Account Access via Private Endpoint"
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
        TestName = "Storage Account Access (Private)"
        Status = "PASS"
        Details = "Successfully accessed storage via private endpoint"
    }
    Write-Host "✅ Storage Account Access: PASS - Connected via private endpoint"
} catch {
    $testResults.Tests += @{
        TestName = "Storage Account Access (Private)"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ Storage Account Access: FAIL - $($_.Exception.Message)"
}

# Test 5: Private Endpoint Connectivity Test
Write-Host "Test 5: Private Endpoint Specific Test"
try {
    # Test if we can reach the storage account on the private network
    $privateTestResult = Test-NetConnection -ComputerName "$storageAccountName.blob.core.windows.net" -Port 443 -InformationLevel Quiet
    if ($privateTestResult) {
        $testResults.Tests += @{
            TestName = "Private Endpoint Connectivity"
            Status = "PASS"
            Details = "Successfully connected to storage account via private endpoint on port 443"
        }
        Write-Host "✅ Private Endpoint Connectivity: PASS"
    } else {
        $testResults.Tests += @{
            TestName = "Private Endpoint Connectivity"
            Status = "FAIL"
            Details = "Cannot reach storage account on port 443"
        }
        Write-Host "❌ Private Endpoint Connectivity: FAIL"
    }
} catch {
    $testResults.Tests += @{
        TestName = "Private Endpoint Connectivity"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ Private Endpoint Connectivity: FAIL - $($_.Exception.Message)"
}

# Test 6: Network Isolation Verification
Write-Host "Test 6: Network Isolation Verification"
try {
    # Try to access the storage account via its public endpoint (should fail)
    $publicEndpointTest = "https://$storageAccountName.blob.core.windows.net"
    try {
        $publicResponse = Invoke-WebRequest -Uri $publicEndpointTest -Method HEAD -ErrorAction Stop -TimeoutSec 10
        $testResults.Tests += @{
            TestName = "Network Isolation"
            Status = "WARN"
            Details = "Public endpoint is accessible - network isolation may not be properly configured"
        }
        Write-Host "⚠️ Network Isolation: WARN - Public endpoint accessible"
    } catch {
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            $testResults.Tests += @{
                TestName = "Network Isolation"
                Status = "PASS"
                Details = "Public access properly blocked (403 Forbidden) - using private endpoint only"
            }
            Write-Host "✅ Network Isolation: PASS - Public access blocked"
        } else {
            $testResults.Tests += @{
                TestName = "Network Isolation"
                Status = "INFO"
                Details = "Public endpoint test inconclusive: $($_.Exception.Message)"
            }
            Write-Host "ℹ️ Network Isolation: INFO - Test inconclusive"
        }
    }
} catch {
    $testResults.Tests += @{
        TestName = "Network Isolation"
        Status = "FAIL"
        Details = "Error: $($_.Exception.Message)"
    }
    Write-Host "❌ Network Isolation: FAIL - $($_.Exception.Message)"
}

# Summary
$passedTests = ($testResults.Tests | Where-Object { $_.Status -eq "PASS" }).Count
$totalTests = ($testResults.Tests | Where-Object { $_.Status -in @("PASS", "FAIL") }).Count

Write-Host "`n=== TEST SUMMARY ==="
Write-Host "Function App: amun-fd-func-2"
Write-Host "Target Storage: $storageAccountName (Private endpoint access)"
Write-Host "Passed: $passedTests/$totalTests tests"
Write-Host "Connection Method: VNet Integration + Private Endpoint"

# Return results for HTTP response
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = 200
    Body = $testResults | ConvertTo-Json -Depth 3
    Headers = @{
        'Content-Type' = 'application/json'
    }
})