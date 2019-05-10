#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

cd "C:\Stemcell-Build\Downloads"

# Install Windows Management Framework 5.1
Write-Output "Installing Windows Management Framework 5.1 - Windows update KB3191564..."
.\WindowsManagmentFramework.msu /quiet /norestart /log
Wait-Process -Name wusa

# Install Visual Studio "ASP.NET and web development" module
Write-Output "Installing Visual Studio 'ASP.NET and web development' module..."
.\VisualStudio-Installer.exe --passive --wait --norestart `
  --add Microsoft.VisualStudio.Workload.NetWeb --includeRecommended --includeOptional
Wait-Process -Name VisualStudio-Installer

# Copy NuGet to system path
Write-Output "Copying NuGet.exe to C:\Windows..."
Copy ".\NuGet.exe" "C:\Windows"

Stop-Transcript
