#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"
$TempPath = "C:\Stemcell-Build\Temp"

#
# Function to unzip files to a particular destination
#
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

$UpdateFilePath="$TempPath\KB3191564"
New-Item "$UpdateFilePath" -ItemType Directory

# Install Windows Management Framework 5.1
Write-Output "Installing Windows Management Framework 5.1 - Windows update KB3191564..."

wusa.exe $DownloadPath\WindowsManagmentFramework.msu `
  /extract:$UpdateFilePath
dism.exe /NoRestart /Online `
  /Add-Package /PackagePath:$UpdateFilePath\WindowsBlue-KB3191564-x64.cab

# Copy LGPO.exe to C:\Windows
Write-Output "Installing LGPO.exe to C:\Windows..."
Unzip `
  "$DownloadPath\LGPO.zip" `
  "$TempPath"
Copy-Item `
  -Path "$TempPath\LGPO.exe" `
  -Destination "C:\Windows"
