# Test Function App 2 Accessibility
# This script tests whether Function App 2 is accessible and helps verify IP restrictions

param(
    [Parameter(Mandatory = $false)]
    [string]$FunctionAppName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "tf-demo",
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails
)

function Get-FunctionAppURL {
    param($AppName, $ResourceGroup)
    
    try {
        # Get the function app details
        $functionApp = az functionapp show --name $AppName --resource-group $ResourceGroup --query "defaultHostName" --output tsv
        if ($functionApp) {
            return "https://$functionApp"
        }
    } catch {
        Write-Error "Could not get Function App URL: $_"
    }
    return $null
}

function Test-FunctionAppAccess {
    param($BaseURL)
    
    Write-Host "`n=== Testing Function App 2 Access ===" -ForegroundColor Cyan
    Write-Host "Base URL: $BaseURL" -ForegroundColor Gray
    
    # Test the main site
    Write-Host "`nTesting main site..." -NoNewline
    try {
        $response = Invoke-WebRequest -Uri $BaseURL -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host " ✓ SUCCESS" -ForegroundColor Green
        } else {
            Write-Host " ✗ FAILED (Status: $($response.StatusCode))" -ForegroundColor Red
        }
    } catch {
        Write-Host " ✗ FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        
        if ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
            Write-Host "  This likely means IP restrictions are blocking your access." -ForegroundColor Yellow
        }
    }
    
    # Test specific function endpoints if available
    $testEndpoints = @(
        "/api/HealthCheck",
        "/api/SimpleTest",
        "/api/NetworkDiagnostics",
        "/api/TestPrivateStorageConnection",
        "/api/TestStorageSimple"
    )
    
    foreach ($endpoint in $testEndpoints) {
        Write-Host "`nTesting $endpoint..." -NoNewline
        try {
            $response = Invoke-WebRequest -Uri "$BaseURL$endpoint" -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host " ✓ SUCCESS" -ForegroundColor Green
                if ($ShowDetails -and $response.Content) {
                    $content = $response.Content
                    if ($content.Length -gt 200) {
                        $content = $content.Substring(0, 200) + "..."
                    }
                    Write-Host "  Response: $content" -ForegroundColor Gray
                }
            } else {
                Write-Host " ⚠ Status: $($response.StatusCode)" -ForegroundColor Yellow
            }
        } catch {
            if ($_.Exception.Message -like "*404*" -or $_.Exception.Message -like "*Not Found*") {
                Write-Host " ⚠ NOT FOUND (endpoint may not exist)" -ForegroundColor Yellow
            } elseif ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
                Write-Host " ✗ FORBIDDEN (IP restriction)" -ForegroundColor Red
            } else {
                Write-Host " ✗ FAILED" -ForegroundColor Red
                if ($ShowDetails) {
                    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

function Get-MyPublicIP {
    try {
        $response = Invoke-RestMethod -Uri "https://ipinfo.io/json" -TimeoutSec 10
        return $response.ip
    } catch {
        return "Unknown"
    }
}

# Main script execution
Write-Host "=== Function App 2 Access Test ===" -ForegroundColor Cyan

# Get current IP
$myIP = Get-MyPublicIP
Write-Host "Your current public IP: $myIP" -ForegroundColor Yellow

# If function app name not provided, try to get it from terraform variables
if (-not $FunctionAppName) {
    $terraformVarsFile = Join-Path $PSScriptRoot "..\terraform\terraform.tfvars"
    if (Test-Path $terraformVarsFile) {
        $content = Get-Content $terraformVarsFile
        $nameVar = $content | Where-Object { $_ -match "^function_app_2_name" }
        if ($nameVar) {
            $FunctionAppName = $nameVar.Split('"')[1]
        }
    }
    
    # If still not found, use default pattern
    if (-not $FunctionAppName) {
        $FunctionAppName = "func-app-2-test-eus"  # Default based on typical naming
        Write-Host "Using default function app name: $FunctionAppName" -ForegroundColor Yellow
        Write-Host "If this is incorrect, provide the name with -FunctionAppName parameter" -ForegroundColor Yellow
    }
}

Write-Host "Testing Function App: $FunctionAppName" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Gray

# Get function app URL
$baseURL = Get-FunctionAppURL -AppName $FunctionAppName -ResourceGroup $ResourceGroupName

if ($baseURL) {
    Test-FunctionAppAccess -BaseURL $baseURL
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Function App: $FunctionAppName"
    Write-Host "Your IP: $myIP"
    Write-Host "`nTo manage access restrictions, use:"
    Write-Host ".\Configure-FunctionApp2-Access.ps1 -ShowCurrentConfig" -ForegroundColor Gray
} else {
    Write-Error "Could not determine Function App URL. Please check:"
    Write-Host "1. Function app name is correct: $FunctionAppName" -ForegroundColor Yellow
    Write-Host "2. Resource group exists: $ResourceGroupName" -ForegroundColor Yellow
    Write-Host "3. You are logged into Azure CLI (az login)" -ForegroundColor Yellow
}