#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"

# Install NuGet provider requirement
Write-Output "Installing NuGet provider requirement..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install PSWindowsUpdate package
Write-Output "Installing PSWindowsUpdate module..."
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name PSWindowsUpdate
