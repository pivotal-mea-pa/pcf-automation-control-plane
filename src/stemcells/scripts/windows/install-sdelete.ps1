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

# Unzip zip sdelete
Write-Output "Extracting client packages..."
Unzip `
 "$DownloadPath\SDelete.zip" `
 "$TempPath"

Move-Item -Path "$TempPath\sdelete*.exe" -Destination "C:\Windows"
