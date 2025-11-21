#Requires -Module Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Assigns role assignments to Function App managed identities for storage access.
    
.DESCRIPTION
    This script assigns the required role assignments that were commented out from Terraform
    to work around dependency issues with managed identity creation timing.
    
.PARAMETER ResourceGroupName
    The resource group containing the resources
    
.PARAMETER SubscriptionId
    The Azure subscription ID (optional, uses current context if not provided)
    
.EXAMPLE
    .\Assign-RoleAssignments.ps1 -ResourceGroupName "tf-demo"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId
)

# Set subscription context if provided
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId
}

Write-Host "Starting role assignment process..." -ForegroundColor Green

try {
    # Get the Function Apps
    Write-Host "Getting Function App managed identities..." -ForegroundColor Yellow
    $funcApp1 = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name "amun-fd-func-1"
    $funcApp2 = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name "amun-fd-func-2"
    
    # Get the Storage Accounts
    Write-Host "Getting Storage Accounts..." -ForegroundColor Yellow
    $storageAccount1 = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name "stgsnefffds1"
    $storageAccount2 = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name "stgsnefffds2"
    
    # Get managed identity principal IDs
    $funcApp1PrincipalId = $funcApp1.Identity.PrincipalId
    $funcApp2PrincipalId = $funcApp2.Identity.PrincipalId
    
    Write-Host "Function App 1 Principal ID: $funcApp1PrincipalId" -ForegroundColor Cyan
    Write-Host "Function App 2 Principal ID: $funcApp2PrincipalId" -ForegroundColor Cyan
    
    # Function App 1 - Storage Blob Data Contributor on Storage Account 1
    Write-Host "Assigning Function App 1 -> Storage Account 1 (Storage Blob Data Contributor)..." -ForegroundColor Yellow
    New-AzRoleAssignment -ObjectId $funcApp1PrincipalId -RoleDefinitionName "Storage Blob Data Contributor" -Scope $storageAccount1.Id -ErrorAction SilentlyContinue
    
    # Function App 2 - Storage Blob Data Contributor on Storage Account 2
    Write-Host "Assigning Function App 2 -> Storage Account 2 (Storage Blob Data Contributor)..." -ForegroundColor Yellow
    New-AzRoleAssignment -ObjectId $funcApp2PrincipalId -RoleDefinitionName "Storage Blob Data Contributor" -Scope $storageAccount2.Id -ErrorAction SilentlyContinue
    
    # Optional: Cross-access for testing
    Write-Host "Assigning cross-access permissions for testing..." -ForegroundColor Yellow
    
    # Function App 1 can read Storage Account 2
    New-AzRoleAssignment -ObjectId $funcApp1PrincipalId -RoleDefinitionName "Storage Blob Data Reader" -Scope $storageAccount2.Id -ErrorAction SilentlyContinue
    
    # Function App 2 can read Storage Account 1
    New-AzRoleAssignment -ObjectId $funcApp2PrincipalId -RoleDefinitionName "Storage Blob Data Reader" -Scope $storageAccount1.Id -ErrorAction SilentlyContinue
    
    Write-Host "✅ Role assignments completed successfully!" -ForegroundColor Green
    
    # Display current role assignments
    Write-Host "`nCurrent role assignments:" -ForegroundColor Cyan
    Write-Host "Function App 1 ($($funcApp1.Name)):" -ForegroundColor White
    Get-AzRoleAssignment -ObjectId $funcApp1PrincipalId | Select-Object RoleDefinitionName, Scope | Format-Table
    
    Write-Host "Function App 2 ($($funcApp2.Name)):" -ForegroundColor White
    Get-AzRoleAssignment -ObjectId $funcApp2PrincipalId | Select-Object RoleDefinitionName, Scope | Format-Table
    
} catch {
    Write-Error "Failed to assign roles: $($_.Exception.Message)"
    exit 1
}

Write-Host "Role assignment script completed!" -ForegroundColor Green