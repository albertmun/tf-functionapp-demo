# Configure Function App 2 Access Restrictions
# This script helps you manage IP access restrictions for Function App 2

param(
    [Parameter(Mandatory = $false)]
    [switch]$EnableRestrictions,
    
    [Parameter(Mandatory = $false)]
    [switch]$DisableRestrictions,
    
    [Parameter(Mandatory = $false)]
    [string]$APIMIPAddress = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateMyIP,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowCurrentConfig
)

$terraformDir = Join-Path $PSScriptRoot "..\terraform"
$terraformVarsFile = Join-Path $terraformDir "terraform.tfvars"

function Get-MyPublicIP {
    try {
        $response = Invoke-RestMethod -Uri "https://ipinfo.io/json" -TimeoutSec 10
        return $response.ip
    } catch {
        Write-Warning "Could not get public IP from ipinfo.io, trying alternative..."
        try {
            $response = Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 10
            return $response.ip
        } catch {
            Write-Error "Could not determine your public IP address"
            return $null
        }
    }
}

function Update-TerraformVars {
    param(
        [hashtable]$Variables
    )
    
    # Read existing vars or create new content
    $varsContent = @()
    if (Test-Path $terraformVarsFile) {
        $varsContent = Get-Content $terraformVarsFile
    }
    
    foreach ($varName in $Variables.Keys) {
        $varValue = $Variables[$varName]
        
        # Handle boolean values properly (don't quote them)
        if ($varValue -is [bool] -or $varValue -eq "true" -or $varValue -eq "false") {
            $varLine = "$varName = $varValue"
        } else {
            $varLine = "$varName = `"$varValue`""
        }
        
        # Check if variable already exists in file
        $existingLineIndex = -1
        for ($i = 0; $i -lt $varsContent.Count; $i++) {
            if ($varsContent[$i] -match "^$varName\s*=") {
                $existingLineIndex = $i
                break
            }
        }
        
        if ($existingLineIndex -ge 0) {
            # Update existing variable
            $varsContent[$existingLineIndex] = $varLine
        } else {
            # Add new variable
            $varsContent += $varLine
        }
    }
    
    # Write back to file
    $varsContent | Set-Content $terraformVarsFile
    Write-Host "Updated $terraformVarsFile" -ForegroundColor Green
}

function Show-CurrentConfiguration {
    Write-Host "`n=== Current Function App 2 Configuration ===" -ForegroundColor Cyan
    
    if (Test-Path $terraformVarsFile) {
        $content = Get-Content $terraformVarsFile
        
        $myIP = $content | Where-Object { $_ -match "^my_current_ip" }
        $apimIP = $content | Where-Object { $_ -match "^apim_ip_address" }
        $restrictions = $content | Where-Object { $_ -match "^enable_function_app_2_restrictions" }
        
        Write-Host "My Current IP: " -NoNewline
        if ($myIP) { 
            Write-Host $myIP.Split('"')[1] -ForegroundColor Yellow 
        } else { 
            Write-Host "Not set" -ForegroundColor Red 
        }
        
        Write-Host "APIM IP Address: " -NoNewline
        if ($apimIP -and $apimIP.Split('"')[1]) { 
            Write-Host $apimIP.Split('"')[1] -ForegroundColor Yellow 
        } else { 
            Write-Host "Not set" -ForegroundColor Red 
        }
        
        Write-Host "Restrictions Enabled: " -NoNewline
        if ($restrictions) { 
            $enabled = $restrictions.Split('=')[1].Trim()
            if ($enabled -eq "true") {
                Write-Host "YES" -ForegroundColor Red
            } else {
                Write-Host "NO" -ForegroundColor Green
            }
        } else { 
            Write-Host "NO (default)" -ForegroundColor Green 
        }
    } else {
        Write-Host "No terraform.tfvars file found - using defaults" -ForegroundColor Yellow
        Write-Host "My Current IP: 107.139.218.54 (default)"
        Write-Host "APIM IP Address: Not set"
        Write-Host "Restrictions Enabled: NO (default)"
    }
    
    Write-Host "`n=== Testing Instructions ===" -ForegroundColor Cyan
    Write-Host "1. To test with restrictions OFF (unrestricted access):"
    Write-Host "   .\Configure-FunctionApp2-Access.ps1 -DisableRestrictions"
    Write-Host "   terraform apply" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. To test with restrictions ON (your IP + APIM only):"
    Write-Host "   .\Configure-FunctionApp2-Access.ps1 -EnableRestrictions -APIMIPAddress 'x.x.x.x'"
    Write-Host "   terraform apply" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. To update your IP address (if it changes):"
    Write-Host "   .\Configure-FunctionApp2-Access.ps1 -UpdateMyIP"
    Write-Host "   terraform apply" -ForegroundColor Gray
}

# Main script logic
if ($ShowCurrentConfig) {
    Show-CurrentConfiguration
    return
}

if ($UpdateMyIP) {
    Write-Host "Detecting your current public IP..." -ForegroundColor Yellow
    $currentIP = Get-MyPublicIP
    if ($currentIP) {
        Write-Host "Your current IP: $currentIP" -ForegroundColor Green
        Update-TerraformVars @{ "my_current_ip" = $currentIP }
        Write-Host "IP address updated. Run 'terraform apply' to apply changes." -ForegroundColor Cyan
    }
    return
}

if ($EnableRestrictions) {
    Write-Host "Enabling IP restrictions for Function App 2..." -ForegroundColor Yellow
    
    $vars = @{ "enable_function_app_2_restrictions" = $true }
    
    # Update IP if needed
    $currentIP = Get-MyPublicIP
    if ($currentIP) {
        $vars["my_current_ip"] = $currentIP
        Write-Host "Your current IP: $currentIP" -ForegroundColor Green
    }
    
    # Set APIM IP if provided
    if ($APIMIPAddress) {
        $vars["apim_ip_address"] = $APIMIPAddress
        Write-Host "APIM IP address: $APIMIPAddress" -ForegroundColor Green
    }
    
    Update-TerraformVars $vars
    
    Write-Host "`nRestrictions ENABLED. Function App 2 will only accept traffic from:" -ForegroundColor Red
    Write-Host "  - Your IP: $currentIP" -ForegroundColor Yellow
    if ($APIMIPAddress) {
        Write-Host "  - APIM IP: $APIMIPAddress" -ForegroundColor Yellow
    }
    Write-Host "`nRun 'terraform apply' to apply these restrictions." -ForegroundColor Cyan
}

if ($DisableRestrictions) {
    Write-Host "Disabling IP restrictions for Function App 2..." -ForegroundColor Yellow
    
    Update-TerraformVars @{ "enable_function_app_2_restrictions" = $false }
    
    Write-Host "Restrictions DISABLED. Function App 2 will accept traffic from anywhere." -ForegroundColor Green
    Write-Host "Run 'terraform apply' to remove restrictions." -ForegroundColor Cyan
}

if (-not $EnableRestrictions -and -not $DisableRestrictions -and -not $UpdateMyIP) {
    Show-CurrentConfiguration
}