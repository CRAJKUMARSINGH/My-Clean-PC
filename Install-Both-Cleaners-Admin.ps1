# Backward-compatible wrapper for Install-Cleaners-Admin.ps1 -Task Both
param(
    [switch]$AlreadyElevated
)

$scriptPath = Join-Path $PSScriptRoot "Install-Cleaners-Admin.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath -Task Both
