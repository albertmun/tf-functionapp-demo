using namespace System.Net

param($Request, $TriggerMetadata)

# Simple health check - just return basic info without doing any network calls
try {
    $result = @{
        Status = "SUCCESS"
        FunctionApp = "amun-fd-func-2"
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        Environment = @{
            WEBSITE_VNET_ROUTE_ALL = $env:WEBSITE_VNET_ROUTE_ALL
            STORAGE_ACCOUNT_2_NAME = $env:STORAGE_ACCOUNT_2_NAME
            STORAGE_ACCOUNT_2_ENDPOINT = $env:STORAGE_ACCOUNT_2_ENDPOINT
            FUNCTIONS_WORKER_RUNTIME = $env:FUNCTIONS_WORKER_RUNTIME
        }
        PowerShell = @{
            Version = $PSVersionTable.PSVersion.ToString()
            Edition = $PSVersionTable.PSEdition
        }
        Message = "Function App 2 is running - this is a basic health check"
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($result | ConvertTo-Json -Depth 3)
    })
}
catch {
    $errorResult = @{
        Status = "ERROR"
        Error = $_.Exception.Message
        Type = $_.Exception.GetType().Name
        StackTrace = $_.ScriptStackTrace
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
    }
    
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::InternalServerError
        Headers = @{ "Content-Type" = "application/json" }
        Body = ($errorResult | ConvertTo-Json -Depth 3)
    })
}