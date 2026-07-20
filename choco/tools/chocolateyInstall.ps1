$ErrorActionPreference = 'Stop'

$packageName = 'my-clean-pc'
$toolsDir    = Split-Path -Parent $MyInvocation.MyCommand.Definition

# -- Download the portable exe from the matching GitHub Release --------------
$version = $env:ChocolateyPackageVersion
$url     = "https://github.com/CRAJKUMARSINGH/My-Clean-PC/releases/download/v$version/MyCleanPC-Portable.exe"

$packageArgs = @{
    packageName    = $packageName
    fileFullPath   = Join-Path $toolsDir 'MyCleanPC-Portable.exe'
    url64bit       = $url
    checksum64     = ''         # filled in by maintainer per release
    checksumType64 = 'sha256'
}

# Download the exe
Get-ChocolateyWebFile @packageArgs

# Create a shim so `my-clean-pc` works from any command prompt
# (Chocolatey auto-shimming picks up .exe files in the tools dir)
Write-Host "my-clean-pc installed. Run: my-clean-pc" -ForegroundColor Green
