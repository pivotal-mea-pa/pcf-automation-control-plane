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

# Add Bosh PowerShell modules
Write-Output "Adding Bosh PowerShell modules..."
Unzip `
  "$DownloadPath\Bosh-PSModules.zip" `
  "C:\Program Files\WindowsPowerShell\Modules"

$ErrorActionPreference = "SilentlyContinue"

# Prepare windows for Bosh
Write-Output "Installing CFFeatures..."
Install-CFFeatures

# Install Bosh agent and SSHD service
Write-Output "Installing Bosh agent..."
Install-Agent -IaaS openstack -agentZipPath "$DownloadPath\Bosh-Agent.zip"
Write-Output "Installing SSH service..."
Install-SSHD -SSHZipFile "$DownloadPath\OpenSSH-Win64.zip"

$ErrorActionPreference = "Stop"

# Re-enable RDP
Set-ItemProperty `
  -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
  -Name "fDenyTSConnections" -Value 0 -Verbose
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose
