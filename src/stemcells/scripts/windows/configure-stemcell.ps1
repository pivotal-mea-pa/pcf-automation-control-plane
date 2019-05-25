
Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

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
Install-CFFeatures

$ErrorActionPreference = "Stop"
