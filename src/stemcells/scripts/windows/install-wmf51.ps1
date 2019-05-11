#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"
$TempPath = "C:\Stemcell-Build\Temp"

$UpdateFilePath="$TempPath\KB3191564"
New-Item "$UpdateFilePath" -ItemType Directory

# Install Windows Management Framework 5.1
Write-Output "Installing Windows Management Framework 5.1 - Windows update KB3191564..."

wusa.exe $DownloadPath\WindowsManagmentFramework.msu `
  /extract:$UpdateFilePath
dism.exe /NoRestart /Online `
  /Add-Package /PackagePath:$UpdateFilePath\WindowsBlue-KB3191564-x64.cab
