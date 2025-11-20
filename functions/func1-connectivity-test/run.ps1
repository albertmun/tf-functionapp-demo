# Function App 1 - Storage Connectivity Test
# Tests connectivity from Function App 1 to Storage Account 1 using IP restrictions

param($Request, $TriggerMetadata)

# Import the script content
. "$PSScriptRoot\..\..\scripts\Test-FunctionApp1-Connectivity.ps1"