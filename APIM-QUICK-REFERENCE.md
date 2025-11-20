# Quick Reference: APIM API Operations

## Base URL
```
https://apim-fd-public-test2.azure-api.net/funcapp2
```

## Available Endpoints

### 1. Health Check
```bash
GET /funcapp2/HealthCheck
```
**Purpose**: Verify Function App 2 is running and responsive

**Example**:
```powershell
Invoke-RestMethod -Uri "https://apim-fd-public-test2.azure-api.net/funcapp2/HealthCheck"
```

---

### 2. Simple Test
```bash
GET /funcapp2/SimpleTest
```
**Purpose**: Basic connectivity test

**Example**:
```powershell
Invoke-RestMethod -Uri "https://apim-fd-public-test2.azure-api.net/funcapp2/SimpleTest"
```

---

### 3. Network Diagnostics
```bash
GET /funcapp2/NetworkDiagnostics
```
**Purpose**: Get network configuration details from Function App 2

**Example**:
```powershell
Invoke-RestMethod -Uri "https://apim-fd-public-test2.azure-api.net/funcapp2/NetworkDiagnostics"
```

---

### 4. Test Private Storage Connection
```bash
GET /funcapp2/TestPrivateStorageConnection
```
**Purpose**: Test connection to private storage account via private endpoint

**Example**:
```powershell
Invoke-RestMethod -Uri "https://apim-fd-public-test2.azure-api.net/funcapp2/TestPrivateStorageConnection"
```

---

### 5. Test Storage Simple
```bash
GET /funcapp2/TestStorageSimple
```
**Purpose**: Simple storage connectivity test

**Example**:
```powershell
Invoke-RestMethod -Uri "https://apim-fd-public-test2.azure-api.net/funcapp2/TestStorageSimple"
```

---

## Get All Endpoints from Terraform

```bash
cd terraform
terraform output apim_api_endpoints
```

## Test All Endpoints

```powershell
.\scripts\Test-APIM-Integration.ps1
```

## With Subscription Key (if enabled)

```powershell
$headers = @{
    "Ocp-Apim-Subscription-Key" = "your-subscription-key-here"
}

Invoke-RestMethod -Uri "https://apim-fd-public-test2.azure-api.net/funcapp2/HealthCheck" -Headers $headers
```

## Terraform Resources Created

| Resource Type | Name | Purpose |
|---------------|------|---------|
| `azurerm_api_management_api` | `func_app_2_api` | Main API container |
| `azurerm_api_management_backend` | `func_app_2_backend` | Backend routing config |
| `azurerm_api_management_api_operation` | `healthcheck` | Health check endpoint |
| `azurerm_api_management_api_operation` | `network_diagnostics` | Network diagnostics endpoint |
| `azurerm_api_management_api_operation` | `simple_test` | Simple test endpoint |
| `azurerm_api_management_api_operation` | `test_private_storage` | Private storage test endpoint |
| `azurerm_api_management_api_operation` | `test_storage_simple` | Simple storage test endpoint |
| `azurerm_api_management_api_policy` | `func_app_2_policy` | CORS and routing policy |

## Adding New Operations

To add a new function operation, edit `terraform/main.tf`:

```hcl
resource "azurerm_api_management_api_operation" "new_operation" {
  operation_id        = "new-operation"
  api_name            = azurerm_api_management_api.func_app_2_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = data.azurerm_resource_group.demo.name
  display_name        = "New Operation"
  method              = "GET"
  url_template        = "/NewFunction"
  description         = "Description of the new function"

  response {
    status_code = 200
    description = "Success"
  }
}
```

Then run:
```bash
terraform apply
```

## Benefits

✅ **No Manual Configuration** - API operations created automatically with deployment  
✅ **Version Controlled** - All API config stored in Git  
✅ **Consistent** - API structure always matches Function App  
✅ **Easy Testing** - Test script validates all endpoints  
✅ **Secure** - Function App 2 protected by IP restrictions (only APIM + your IP)
