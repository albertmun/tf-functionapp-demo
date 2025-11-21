# Deploy Function Apps Script
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionApp1Name = "amun-fd-func-1",
    
    [Parameter(Mandatory=$false)]
    [string]$FunctionApp2Name = "amun-fd-func-2"
)

Write-Host "Deploying Function Apps..." -ForegroundColor Green

# Set script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProjectRoot = Split-Path -Parent $ScriptDir
$FunctionsDir = Join-Path $ProjectRoot "functions"

# Function to create and deploy a zip package
function Deploy-FunctionApp {
    param($AppName, $SourceDir)
    
    Write-Host "Deploying $AppName..." -ForegroundColor Yellow
    
    $ZipPath = Join-Path $env:TEMP "$AppName.zip"
    
    try {
        # Create zip package
        if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
        
        # Use .NET to create the zip (more reliable than Compress-Archive for large files)
        [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDir, $ZipPath)
        
        Write-Host "Created zip package: $ZipPath" -ForegroundColor Cyan
        
        # Deploy using Azure CLI
        $deployResult = az functionapp deployment source config-zip `
            --resource-group $ResourceGroupName `
            --name $AppName `
            --src $ZipPath `
            --output json | ConvertFrom-Json
            
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully deployed $AppName" -ForegroundColor Green
            Write-Host "Function URL: https://$AppName.azurewebsites.net" -ForegroundColor Cyan
        } else {
            Write-Error "❌ Failed to deploy $AppName"
        }
        
        # Cleanup
        Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Error "Error deploying $AppName`: $($_.Exception.Message)"
    }
}

# Check if Azure CLI is logged in
Write-Host "Checking Azure CLI authentication..." -ForegroundColor Yellow
$accountInfo = az account show 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Please run 'az login' first to authenticate with Azure CLI"
    exit 1
}

Write-Host "Authenticated with Azure CLI" -ForegroundColor Green

# Deploy Function App 1
$funcApp1Dir = Join-Path $FunctionsDir "func-app-1"
if (Test-Path $funcApp1Dir) {
    Deploy-FunctionApp -AppName $FunctionApp1Name -SourceDir $funcApp1Dir
} else {
    Write-Warning "Function App 1 directory not found: $funcApp1Dir"
}

# Deploy Function App 2
$funcApp2Dir = Join-Path $FunctionsDir "func-app-2"
if (Test-Path $funcApp2Dir) {
    Deploy-FunctionApp -AppName $FunctionApp2Name -SourceDir $funcApp2Dir
} else {
    Write-Warning "Function App 2 directory not found: $funcApp2Dir"
}

Write-Host "`n🎉 Function App deployment completed!" -ForegroundColor Green
Write-Host "Test URLs:" -ForegroundColor Cyan
Write-Host "  Function App 1: https://$FunctionApp1Name.azurewebsites.net/api/TestStorageConnection" -ForegroundColor Cyan
Write-Host "  Function App 2: https://$FunctionApp2Name.azurewebsites.net/api/TestPrivateStorageConnection" -ForegroundColor Cyan