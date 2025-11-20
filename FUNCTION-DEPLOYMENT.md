# Azure Function Apps Demo - Storage Access Patterns

This demo showcases two different patterns for Azure Function Apps to access Azure Storage:

## Architecture Overview

### Pattern 1: IP Restrictions
- **Function App**: `sneff-fd-func-1`
- **Storage Account**: `stgsnefffds1` (public with IP restrictions)
- **Access Method**: Function App's outbound IPs are whitelisted in storage account network rules

### Pattern 2: Private Endpoints  
- **Function App**: `sneff-fd-func-2` 
- **Storage Account**: `stgsnefffds2` (private endpoint only)
- **Access Method**: Function App uses VNet integration to access storage via private endpoint

## Deployed Infrastructure

✅ **Resource Group**: `tf-demo`  
✅ **Function Apps**: `sneff-fd-func-1`, `sneff-fd-func-2`  
✅ **Storage Accounts**: `stgsnefffds1`, `stgsnefffds2`  
✅ **App Service Plan**: S1 SKU (Windows)  
✅ **Virtual Network**: With subnets for VNet integration and private endpoints  
✅ **Private DNS Zone**: For private endpoint resolution  

## Function App Code Deployment

The infrastructure is deployed, but you need to deploy the function code:

### Option 1: Using PowerShell Script (Recommended)
```powershell
# Run from the repository root
.\scripts\Deploy-FunctionApps.ps1 -ResourceGroupName "tf-demo"
```

### Option 2: Manual Azure CLI Deployment
```bash
# Function App 1
cd functions/func-app-1
zip -r func-app-1.zip .
az functionapp deployment source config-zip --resource-group tf-demo --name sneff-fd-func-1 --src func-app-1.zip

# Function App 2  
cd ../func-app-2
zip -r func-app-2.zip .
az functionapp deployment source config-zip --resource-group tf-demo --name sneff-fd-func-2 --src func-app-2.zip
```

### Option 3: Visual Studio Code
1. Install Azure Functions extension
2. Right-click on function folder → "Deploy to Function App"

## Testing the Functions

After deploying the code, test the storage connectivity:

### Function App 1 (IP Restrictions)
```
GET https://sneff-fd-func-1.azurewebsites.net/api/TestStorageConnection
```

**Expected Response:**
```json
{
  "FunctionApp": "sneff-fd-func-1",
  "StorageAccount": "stgsnefffds1", 
  "AccessMethod": "IP Restrictions",
  "Status": "SUCCESS",
  "Message": "Storage account accessible via IP restrictions"
}
```

### Function App 2 (Private Endpoint)
```
GET https://sneff-fd-func-2.azurewebsites.net/api/TestPrivateStorageConnection  
```

**Expected Response:**
```json
{
  "FunctionApp": "sneff-fd-func-2",
  "StorageAccount": "stgsnefffds2",
  "AccessMethod": "VNet Integration + Private Endpoint", 
  "Status": "SUCCESS",
  "Message": "Storage account accessible via private endpoint"
}
```

## Troubleshooting

### "Run From Package Initialization failed"
- **Cause**: No function code deployed to the Function App
- **Solution**: Deploy function code using one of the methods above

### Function App 1 can't access storage
- **Cause**: IP restrictions not properly configured
- **Check**: Function App's outbound IPs are in storage account's allowed IP list
- **Fix**: Update storage account network rules with Function App IPs

### Function App 2 can't access storage  
- **Cause**: VNet integration or private endpoint issues
- **Check**: VNet integration enabled, private endpoint configured, DNS resolution working
- **Fix**: Verify networking configuration

## PowerShell Test Scripts

Use the existing test scripts for local validation:
- `scripts/Test-FunctionApp1-Connectivity.ps1`
- `scripts/Test-FunctionApp2-Connectivity.ps1`

## Next Steps

1. **Deploy Function Code** using the deployment script
2. **Test Connectivity** using the function URLs
3. **Review Network Rules** in Azure Portal
4. **Monitor Function Logs** for detailed diagnostics
5. **Customize Functions** for your specific use cases

## Security Considerations

- Function App 1 uses IP-based access (less secure, simpler setup)
- Function App 2 uses private endpoints (more secure, complex setup)  
- Both approaches have valid use cases depending on requirements
- Consider using Managed Identity for authentication in production