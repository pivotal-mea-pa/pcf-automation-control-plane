#ps1_sysnative

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null

New-Item "C:\Temp\Logs" -ItemType Directory
New-Item "C:\Temp\Downloads" -ItemType Directory

Start-Transcript -path "C:\Temp\Logs\stemcell-config.log" -append
$ErrorActionPreference = "Stop"

# Wait for internet connectivity
Do {
  Write-Host "Waiting for internet connectivity..."
  try {
    $HTTP_Request = [System.Net.WebRequest]::Create('http://google.com')
    $HTTP_Response = $HTTP_Request.GetResponse()
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    $HTTP_Response.Close()
  } catch {
    $HTTP_Status = 500
  }
} Until ($HTTP_Status -eq 200)

#
# Function to unzip files to a particular destination
#
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# Enable TLS12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Ensure .NET 3.5 is installed
# Install-WindowsFeature Net-Framework-Core

# Download Bosh Modules and agent
[string]$BoshVersion = "1200.32"
Invoke-WebRequest `
  -uri "https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${BoshVersion}/bosh-psmodules.zip" `
  -outfile "C:\Temp\Downloads\bosh-psmodules.zip"
Invoke-WebRequest `
  -uri "https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${BoshVersion}/agent.zip" `
  -outfile "C:\Temp\Downloads\agent.zip"

Unzip `
  "C:\Temp\Downloads\bosh-psmodules.zip" `
  "C:\Program Files\WindowsPowerShell\Modules"

$ErrorActionPreference = "SilentlyContinue"
Install-CFFeatures
Protect-CFCell
Install-Agent -IaaS openstack -agentZipPath "C:\Temp\Downloads\agent.zip"
$ErrorActionPreference = "Stop"

# OpenSSH
# [string]$OpenSSHVersion = "v7.9.0.0p1-Beta"
# Invoke-WebRequest `
#   -uri "https://github.com/PowerShell/Win32-OpenSSH/releases/download/${OpenSSHVersion}/OpenSSH-Win64.zip" `
#   -outfile "C:\Temp\Downloads\OpenSSH-Win64.zip"

# Unblock-File "C:\Temp\Downloads\OpenSSH-Win64.zip"
# Install-SSHD -SSHZipFile "C:\Temp\Downloads\OpenSSH-Win64.zip"

# Enable RDP
Set-ItemProperty `
  -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
  -Name "fDenyTSConnections" -Value 0 -Verbose
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose

# Setup command line Windows update module
# Invoke-WebRequest `
#   -uri "https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc/file/41459/47/PSWindowsUpdate.zip" `
#   -outfile "C:\Temp\Downloads\PSWindowsUpdate.zip"

# Unzip `
#   "C:\Temp\Downloads\PSWindowsUpdate.zip" `
#   "C:\Program Files\WindowsPowerShell\Modules"

# # Update windows
# Import-Module PSWindowsUpdate

# $Script = {ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll -AutoReboot `
#   | Out-File -Append C:\Temp\Logs\stemcell-config.log}
# Invoke-WUInstall -ComputerName $env:computername -Script $Script

# Reboot if update does not auto reboot
Stop-Transcript
