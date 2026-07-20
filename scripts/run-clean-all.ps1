# One-click cleanup script
# Requires PowerShell execution policy bypass
Continue = 'SilentlyContinue'
High = 'None'
Continue = 'SilentlyContinue'

# Load core functions
.  \clean-pc-core.ps1

# Execute cleanup steps
Clear-AllInstalledBrowsers
Clear-AppDataJunkSweep '%APPDATA%'
Clear-RigorousTempLocations
Write-Host 'Cleanup completed.'
