#ps1_sysnative

Param(
  [string][Parameter(Mandatory=$True)]$IaaS
)

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$DownloadPath = "C:\Stemcell-Build\Downloads"

Write-Output "Protecting CFCell..."
Protect-CFCell

New-Item "C:\Users\vcap" -ItemType Directory
Write-Output "Installing Bosh agent..."
Install-Agent -IaaS $IaaS -agentZipPath "$DownloadPath\Bosh-Agent.zip"
Write-Output "Installing SSH service..."
Install-SSHD -SSHZipFile "$DownloadPath\OpenSSH-Win64.zip"

Remove-Item –path "C:\Stemcell-Build\Downloads\*"
Remove-Item –path "C:\Stemcell-Build\Temp\*"
Remove-Item –path "$env:SystemRoot\Temp\*"

Write-Output "Optimizing disk..."
Optimize-Disk
Write-Output "Compressing disk..."
Compress-Disk

# Re-enable RDP
Set-ItemProperty `
  -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
  -Name "fDenyTSConnections" -Value 0 -Verbose
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose
