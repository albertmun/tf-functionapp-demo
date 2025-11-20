#Requires -Module Az.Accounts, Az.Resources, Az.Functions

<#
.SYNOPSIS
    Diagnoses Function App 2 500 error by checking VNet integration and connectivity.
    
.DESCRIPTION
    This script checks various configuration items that could cause 500 errors in 
    Function App 2 which uses VNet integration and private endpoints.
    
.PARAMETER ResourceGroupName
    The resource group containing the resources
    
.EXAMPLE
    .\Diagnose-FunctionApp2.ps1 -ResourceGroupName "tf-demo"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName
)

Write-Host "🔍 Diagnosing Function App 2 (sneff-fd-func-2) 500 Error..." -ForegroundColor Yellow

try {
    # Get Function App 2
    Write-Host "`n1. Getting Function App 2 details..." -ForegroundColor Cyan
    $funcApp2 = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name "sneff-fd-func-2"
    
    if (-not $funcApp2) {
        Write-Error "Function App 2 not found!"
        exit 1
    }
    
    Write-Host "   ✅ Function App found: $($funcApp2.Name)" -ForegroundColor Green
    Write-Host "   State: $($funcApp2.State)" -ForegroundColor White
    Write-Host "   Managed Identity: $($funcApp2.Identity.Type)" -ForegroundColor White
    
    # Check VNet Integration
    Write-Host "`n2. Checking VNet Integration..." -ForegroundColor Cyan
    $vnetConnection = Get-AzWebAppVnetIntegration -ResourceGroupName $ResourceGroupName -Name "sneff-fd-func-2"
    
    if ($vnetConnection) {
        Write-Host "   ✅ VNet Integration found" -ForegroundColor Green
        Write-Host "   Subnet: $($vnetConnection.SubnetName)" -ForegroundColor White
        Write-Host "   VNet: $($vnetConnection.VnetResourceId)" -ForegroundColor White
    } else {
        Write-Host "   ❌ No VNet Integration found!" -ForegroundColor Red
    }
    
    # Check App Settings
    Write-Host "`n3. Checking App Settings..." -ForegroundColor Cyan
    $appSettings = Get-AzWebAppApplicationSetting -ResourceGroupName $ResourceGroupName -Name "sneff-fd-func-2"
    
    $criticalSettings = @(
        "WEBSITE_VNET_ROUTE_ALL",
        "AzureWebJobsStorage",
        "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING",
        "FUNCTIONS_EXTENSION_VERSION"
    )
    
    foreach ($setting in $criticalSettings) {
        $value = $appSettings.Properties[$setting]
        if ($value) {
            if ($setting -like "*CONNECTION*" -or $setting -eq "AzureWebJobsStorage") {
                Write-Host "   ✅ $setting: [CONFIGURED]" -ForegroundColor Green
            } else {
                Write-Host "   ✅ $setting: $value" -ForegroundColor Green
            }
        } else {
            Write-Host "   ❌ $setting: NOT SET" -ForegroundColor Red
        }
    }
    
    # Check Storage Account Access
    Write-Host "`n4. Checking Storage Account Access..." -ForegroundColor Cyan
    $storageAccount2 = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name "stgsnefffds2"
    
    if ($storageAccount2) {
        Write-Host "   ✅ Storage Account 2 found: $($storageAccount2.StorageAccountName)" -ForegroundColor Green
        Write-Host "   Network Rules: $($storageAccount2.NetworkRuleSet.DefaultAction)" -ForegroundColor White
        
        # Check if private endpoint exists
        $privateEndpoint = Get-AzPrivateEndpoint -ResourceGroupName $ResourceGroupName -Name "pe-stgsnefffds2" -ErrorAction SilentlyContinue
        if ($privateEndpoint) {
            Write-Host "   ✅ Private Endpoint found: $($privateEndpoint.Name)" -ForegroundColor Green
            Write-Host "   Connection State: $($privateEndpoint.PrivateLinkServiceConnections[0].PrivateLinkServiceConnectionState.Status)" -ForegroundColor White
        } else {
            Write-Host "   ❌ Private Endpoint not found!" -ForegroundColor Red
        }
    }
    
    # Check Role Assignments
    Write-Host "`n5. Checking Role Assignments..." -ForegroundColor Cyan
    $principalId = $funcApp2.Identity.PrincipalId
    
    if ($principalId) {
        $roleAssignments = Get-AzRoleAssignment -ObjectId $principalId -ErrorAction SilentlyContinue
        
        if ($roleAssignments.Count -gt 0) {
            Write-Host "   ✅ Role assignments found:" -ForegroundColor Green
            foreach ($role in $roleAssignments) {
                Write-Host "     - $($role.RoleDefinitionName) on $($role.Scope)" -ForegroundColor White
            }
        } else {
            Write-Host "   ❌ NO ROLE ASSIGNMENTS FOUND!" -ForegroundColor Red
            Write-Host "   This is likely the cause of the 500 error." -ForegroundColor Yellow
            Write-Host "   Run: .\Assign-RoleAssignments.ps1 -ResourceGroupName '$ResourceGroupName'" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ No managed identity principal ID found!" -ForegroundColor Red
    }
    
    # Check Private DNS Zone
    Write-Host "`n6. Checking Private DNS Zone..." -ForegroundColor Cyan
    $privateDnsZone = Get-AzPrivateDnsZone -ResourceGroupName $ResourceGroupName -Name "privatelink.blob.core.windows.net" -ErrorAction SilentlyContinue
    
    if ($privateDnsZone) {
        Write-Host "   ✅ Private DNS Zone found: $($privateDnsZone.Name)" -ForegroundColor Green
        
        # Check VNet link
        $vnetLink = Get-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $ResourceGroupName -ZoneName "privatelink.blob.core.windows.net" -ErrorAction SilentlyContinue
        if ($vnetLink) {
            Write-Host "   ✅ VNet Link found: $($vnetLink.Name)" -ForegroundColor Green
        } else {
            Write-Host "   ❌ VNet Link not found!" -ForegroundColor Red
        }
    } else {
        Write-Host "   ❌ Private DNS Zone not found!" -ForegroundColor Red
    }
    
    Write-Host "`n📋 DIAGNOSIS SUMMARY:" -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Yellow
    
    if ($roleAssignments.Count -eq 0) {
        Write-Host "🔴 LIKELY ISSUE: Missing role assignments" -ForegroundColor Red
        Write-Host "   Function App 2 cannot authenticate to the storage account." -ForegroundColor White
        Write-Host "   SOLUTION: Run .\Assign-RoleAssignments.ps1 -ResourceGroupName '$ResourceGroupName'" -ForegroundColor Green
    } elseif (-not $vnetConnection) {
        Write-Host "🔴 LIKELY ISSUE: VNet Integration not configured" -ForegroundColor Red
        Write-Host "   Function App 2 cannot access private storage through VNet." -ForegroundColor White
    } elseif (-not $privateEndpoint) {
        Write-Host "🔴 LIKELY ISSUE: Private Endpoint not configured" -ForegroundColor Red
        Write-Host "   Storage account cannot be accessed privately." -ForegroundColor White
    } else {
        Write-Host "🟡 Configuration looks correct - check Function App logs for detailed error" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Diagnosis failed: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nDiagnosis completed! ✅" -ForegroundColor Green