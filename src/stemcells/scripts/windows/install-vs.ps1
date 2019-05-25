Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"
CD $DownloadPath

# Install Visual Studio "ASP.NET and web development" module
Write-Output "Installing Visual Studio 'ASP.NET and web development' module..."
.\VisualStudio-Installer.exe --quiet --wait --norestart `
  --add Microsoft.VisualStudio.Workload.NetWeb --includeRecommended --includeOptional
Wait-Process -Name VisualStudio-Installer

# Copy NuGet to system path
Write-Output "Copying NuGet.exe to C:\Windows..."
Copy ".\NuGet.exe" "C:\Windows"
