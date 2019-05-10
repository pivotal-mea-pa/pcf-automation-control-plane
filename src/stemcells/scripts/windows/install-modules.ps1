#ps1_sysnative

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

# Install NuGet provider requirement
Write-Output "Installing NuGet provider requirement..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install PSWindowsUpdate package
Write-Output "Installing PSWindowsUpdate module..."
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name PSWindowsUpdate

# Add Bosh PowerShell modules
Write-Output "Installing Bosh PowerShell modules..."
Unzip `
  "$DownloadPath\Bosh-PSModules.zip" `
  "C:\Program Files\WindowsPowerShell\Modules"

Stop-Transcript
