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

# Copy LGPO.exe to system path
Write-Output "Copying LGPO.exe to C:\Windows..."
Unzip `
  "$DownloadPath\LGPO.zip" `
  "$TempPath"

Copy "$TempPath\LGPO.exe" "C:\Windows"
