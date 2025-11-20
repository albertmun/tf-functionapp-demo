# Function App 2 - Storage Connectivity Test
# Tests connectivity from Function App 2 to Storage Account 2 using Private Endpoint

param($Request, $TriggerMetadata)

# Import the script content
. "$PSScriptRoot\..\..\scripts\Test-FunctionApp2-Connectivity.ps1"