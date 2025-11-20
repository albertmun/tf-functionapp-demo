# APIM Integration for Function App 2

This Terraform configuration automatically creates and configures an API Management (APIM) API for Function App 2.

## What Gets Created

The Terraform configuration automatically creates:

1. **APIM API** (`func-app-2-api`)
   - Display Name: "Function App 2 API"
   - Path: `/funcapp2`
   - Protocol: HTTPS only

2. **Backend Configuration** (`func-app-2-backend`)
   - Points to Function App 2's default hostname
   - Handles routing to the Azure Function

3. **API Operations** (one for each function):
   - `/HealthCheck` - Check health status
   - `/NetworkDiagnostics` - Run network diagnostics
   - `/SimpleTest` - Simple test function
   - `/TestPrivateStorageConnection` - Test private storage connection
   - `/TestStorageSimple` - Simple storage test

4. **API Policy**
   - Sets the backend service
   - Configures CORS for Azure Portal access
   - Handles request/response flow

## Accessing the API

After deployment, you can access Function App 2 through APIM using these URLs:

```
https://{apim-name}.azure-api.net/funcapp2/HealthCheck
https://{apim-name}.azure-api.net/funcapp2/NetworkDiagnostics
https://{apim-name}.azure-api.net/funcapp2/SimpleTest
https://{apim-name}.azure-api.net/funcapp2/TestPrivateStorageConnection
https://{apim-name}.azure-api.net/funcapp2/TestStorageSimple
```

The exact URLs are available in the Terraform outputs:
```bash
terraform output apim_api_endpoints
```

## Authentication

By default, the API is accessible through APIM without requiring Function App keys. If you need to add authentication:

### Option 1: APIM Subscription Keys
Add a subscription requirement to the API in the Azure Portal or via Terraform:

```hcl
resource "azurerm_api_management_api" "func_app_2_api" {
  # ... existing config ...
  subscription_required = true
  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }
}
```

### Option 2: Use Function Keys
Modify the API policy to forward the Function App's function key:

```xml
<inbound>
  <base />
  <set-backend-service backend-id="func-app-2-backend" />
  <set-header name="x-functions-key" exists-action="override">
    <value>{{func-app-2-key}}</value>
  </set-header>
</inbound>
```

Then store the function key as a named value in APIM.

## Adding New Functions

When you add a new function to Function App 2:

1. Add a new operation resource in `main.tf`:

```hcl
resource "azurerm_api_management_api_operation" "new_function" {
  operation_id        = "new-function"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "New Function"
  method              = "GET"
  url_template        = "/NewFunction"
  description         = "Description of the new function"

  response {
    status_code = 200
    description = "Success"
  }
}
```

2. Add the endpoint to outputs in `outputs.tf`:

```hcl
output "apim_api_endpoints" {
  value = {
    # ... existing endpoints ...
    new_function = "https://${azurerm_api_management.apim.gateway_url}/funcapp2/NewFunction"
  }
}
```

3. Run `terraform apply` to create the new operation

## Benefits

- **No Manual Configuration**: API operations are created automatically with each deployment
- **Version Control**: API configuration is stored in Git alongside your infrastructure
- **Consistency**: Ensures API structure matches your Function App
- **Easy Updates**: Add/remove operations by modifying Terraform and redeploying
- **IP Restrictions**: Function App 2 is protected by IP restrictions, only accessible from your IP and APIM

## Testing

Test the API through APIM:

```powershell
# Test health check
Invoke-RestMethod -Uri "https://{apim-name}.azure-api.net/funcapp2/HealthCheck" -Method GET

# Test with subscription key (if enabled)
$headers = @{
    "Ocp-Apim-Subscription-Key" = "your-subscription-key"
}
Invoke-RestMethod -Uri "https://{apim-name}.azure-api.net/funcapp2/HealthCheck" -Method GET -Headers $headers
```

## Troubleshooting

### 404 Not Found
- Verify the function name matches exactly (case-sensitive)
- Check that Function App 2 is running
- Verify the backend URL is correct

### 403 Forbidden
- Check APIM IP is allowed in Function App 2's IP restrictions
- Verify `enable_function_app_2_restrictions` variable
- Check APIM's public IP: `terraform output apim_effective_ip`

### 502 Bad Gateway
- Verify Function App 2 is accessible from APIM
- Check Function App 2's health endpoint directly
- Review Function App logs for errors
