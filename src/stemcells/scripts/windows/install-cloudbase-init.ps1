Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"
$LogPath = "C:\Stemcell-Build\Logs"
CD $DownloadPath

# Install Visual Studio "ASP.NET and web development" module
Write-Output "Installing Cloudbase-Init..."
msiexec /i CloudbaseInitSetup_x64.msi /quiet /norestart /qn `
  /l*v "$LogPath\Cloudbase-Init-Install.log" `
  LOGGINGSERIALPORTNAME="COM1"
Start-Sleep -Seconds 30
Wait-Process -Name msiexec
