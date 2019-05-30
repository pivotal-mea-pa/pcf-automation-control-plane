Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"
$ProgressPreference='SilentlyContinue'

$DownloadPath = "C:\Stemcell-Build\Downloads"

#
# Function to unzip files to a particular destination
#
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Add Bosh PowerShell modules
Write-Output "Adding Bosh PowerShell modules..."
Unzip `
  "$DownloadPath\Bosh-PSModules.zip" `
  "C:\Program Files\WindowsPowerShell\Modules"

$ErrorActionPreference = "SilentlyContinue"

# Prepare windows for Bosh
Write-Output "Installing CFFeatures..."

$OS = Get-WmiObject Win32_OperatingSystem
switch -Wildcard ($OS.Version) {
  "6.3.*" {
    Install-CFFeatures2012
  }
  "10.0.*" {
    Install-CFFeatures2016
  }
  default {
    Write-Error "Unsupported Windows version $($OS.Version)"
  }
}

$ErrorActionPreference = "Stop"
