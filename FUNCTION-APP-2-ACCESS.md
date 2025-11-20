# Function App 2 IP Access Restrictions

This document explains how to manage IP access restrictions for Function App 2, allowing you to test secure configurations while maintaining flexibility.

## Overview

Function App 2 now supports conditional IP access restrictions that can be easily toggled on/off. When enabled, only specified IP addresses can access the function app.

## Features

- **Conditional Restrictions**: Enable/disable restrictions without code changes
- **Your Current IP**: Automatically detects and allows your public IP
- **APIM Integration**: Support for external APIM instance access
- **Easy Testing**: Scripts to toggle restrictions and test access

## Quick Start

### 1. Initial Setup (No Restrictions)

By default, Function App 2 has no IP restrictions:

```powershell
# Deploy with no restrictions (default)
cd terraform
terraform apply
```

### 2. Enable Restrictions for Testing

```powershell
# Configure restrictions (your IP + APIM IP)
.\scripts\Configure-FunctionApp2-Access.ps1 -EnableRestrictions -APIMIPAddress "x.x.x.x"

# Apply the configuration
cd terraform
terraform apply
```

### 3. Test Access

```powershell
# Test function app accessibility
.\scripts\Test-FunctionApp2-Access.ps1 -ShowDetails
```

### 4. Disable Restrictions for Development

```powershell
# Remove restrictions for unrestricted access
.\scripts\Configure-FunctionApp2-Access.ps1 -DisableRestrictions

# Apply the configuration
cd terraform
terraform apply
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_function_app_2_restrictions` | Enable/disable IP restrictions | `false` |
| `my_current_ip` | Your current public IP address | `107.139.218.54` |
| `apim_ip_address` | External APIM instance IP | `""` (empty) |

## Scripts

### Configure-FunctionApp2-Access.ps1

Manages IP access restrictions configuration:

```powershell
# Show current configuration
.\Configure-FunctionApp2-Access.ps1 -ShowCurrentConfig

# Enable restrictions with your current IP
.\Configure-FunctionApp2-Access.ps1 -EnableRestrictions

# Enable restrictions with APIM IP
.\Configure-FunctionApp2-Access.ps1 -EnableRestrictions -APIMIPAddress "20.30.40.50"

# Disable all restrictions
.\Configure-FunctionApp2-Access.ps1 -DisableRestrictions

# Update your IP address (if it changed)
.\Configure-FunctionApp2-Access.ps1 -UpdateMyIP
```

### Test-FunctionApp2-Access.ps1

Tests function app accessibility:

```powershell
# Basic access test
.\Test-FunctionApp2-Access.ps1

# Detailed test with response content
.\Test-FunctionApp2-Access.ps1 -ShowDetails

# Test specific function app
.\Test-FunctionApp2-Access.ps1 -FunctionAppName "your-function-app-name"
```

## Typical Workflow

### Development Phase
1. Keep restrictions disabled for easy development access
2. Test functions from Azure Portal, local tools, etc.

### Security Testing Phase
1. Enable restrictions with your IP and APIM IP
2. Verify blocked access from other IPs
3. Test APIM integration

### Production Deployment
1. Configure production APIM IP addresses
2. Enable restrictions in production environment
3. Monitor access logs

## IP Restriction Rules

When restrictions are enabled, Function App 2 will:

✅ **Allow Access From:**
- Your current public IP address
- Configured APIM instance IP address
- Azure Portal (for management)

❌ **Block Access From:**
- All other IP addresses
- Default action: Deny

## Terraform Configuration

The IP restrictions are implemented using dynamic blocks in the Function App configuration:

```hcl
# Conditional IP restrictions
dynamic "ip_restriction" {
  for_each = var.enable_function_app_2_restrictions ? [
    {
      ip_address = "${var.my_current_ip}/32"
      name       = "AllowMyCurrentIP"
      priority   = 100
      action     = "Allow"
    }
  ] : []
  # ... configuration continues
}

ip_restriction_default_action = var.enable_function_app_2_restrictions ? "Deny" : "Allow"
```

## Troubleshooting

### Access Denied (403 Forbidden)
- Check if restrictions are enabled: `terraform output function_app_2_restrictions_enabled`
- Verify your IP: `.\scripts\Configure-FunctionApp2-Access.ps1 -ShowCurrentConfig`
- Update your IP if it changed: `.\scripts\Configure-FunctionApp2-Access.ps1 -UpdateMyIP`

### APIM Cannot Access Function
- Ensure APIM IP is correctly configured
- Check APIM's outbound IP address (may be different from expected)
- Verify restrictions include the APIM IP: `terraform output function_app_2_allowed_ips`

### Need to Test from Different IP
- Temporarily add the IP to terraform.tfvars:
  ```
  my_current_ip = "new.ip.address.here"
  ```
- Or disable restrictions temporarily:
  ```powershell
  .\scripts\Configure-FunctionApp2-Access.ps1 -DisableRestrictions
  ```

## Best Practices

1. **Keep restrictions disabled during development** for easier testing
2. **Enable restrictions when testing security features**
3. **Use the scripts** rather than manually editing terraform.tfvars
4. **Test access after any IP changes** to ensure functionality
5. **Document APIM IP addresses** for team members
6. **Monitor access logs** in production environments

## Security Notes

- IP restrictions provide network-level access control
- Still requires proper authentication for function execution
- Consider using managed identities for service-to-service communication
- Monitor access logs for unauthorized attempts
- Keep APIM IP addresses up to date