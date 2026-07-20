$ErrorActionPreference = 'SilentlyContinue'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Remove-Item (Join-Path $toolsDir 'MyCleanPC-Portable.exe') -Force -ErrorAction SilentlyContinue
Write-Host "my-clean-pc uninstalled." -ForegroundColor Green
