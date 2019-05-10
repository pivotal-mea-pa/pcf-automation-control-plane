#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"

$ErrorActionPreference = "SilentlyContinue"

Write-Output "Installing CFFeatures..."
Install-CFFeatures

Write-Output "Protecting CFCell..."
Protect-CFCell

Write-Output "Installing Bosh agent..."
Install-Agent -IaaS openstack -agentZipPath "$DownloadPath\agent.zip"

Write-Output "Installing SSH daemon..."
Install-SSHD -SSHZipFile "$DownloadPath\OpenSSH-Win64.zip"

$ErrorActionPreference = "Stop"

# Re-enable RDP
Set-ItemProperty `
  -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
  -Name "fDenyTSConnections" -Value 0 -Verbose
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose

Stop-Transcript
