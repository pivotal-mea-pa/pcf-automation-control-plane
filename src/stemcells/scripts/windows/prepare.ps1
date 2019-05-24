#ps1_sysnative

$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null

New-Item "C:\Stemcell-Build\Logs" -ItemType Directory
New-Item "C:\Stemcell-Build\Downloads" -ItemType Directory
New-Item "C:\Stemcell-Build\Scripts" -ItemType Directory
New-Item "C:\Stemcell-Build\Temp" -ItemType Directory

Write-Output "Running User Data Script"
Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "stop"

Write-Output "Setting Administrator password"
Net User "Administrator" "P@ssw0rd" /logonpasswordchg:no

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

# WinRM
Write-Output "Setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm quickconfig '-transport:http'
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTP" '@{Port="5985"}'
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd.exe /c netsh firewall add portopening TCP 5985 "Port 5985"
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm
cmd.exe /c wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE

Enable-PSRemoting -Force
Restart-Service WinRM

# Disable Windows auto updates via registry
# https://support.microsoft.com/en-us/help/328010
function New-Directory($path) {
  $p, $components = $path -split '[\\/]'
  $components | ForEach-Object {
      $p = "$p\$_"
      if (!(Test-Path $p)) {
          New-Item -ItemType Directory $p | Out-Null
      }
  }
  $null
}
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
New-Directory $auPath 

# Set NoAutoUpdate.
#
# 0: Automatic Updates is enabled (default).
# 1: Automatic Updates is disabled.
New-ItemProperty `
    -Path $auPath `
    -Name NoAutoUpdate `
    -Value 1 `
    -PropertyType DWORD `
    -Force `
    | Out-Null

# Set AUOptions.
# 1: Keep my computer up to date has been disabled in Automatic Updates.
# 2: Notify of download and installation.
# 3: Automatically download and notify of installation.
# 4: Automatically download and scheduled installation.
New-ItemProperty `
    -Path $auPath `
    -Name AUOptions `
    -Value 2 `
    -PropertyType DWORD `
    -Force `
    | Out-Null

# Ensure Windows Defender is uninstalled
Uninstall-WindowsFeature Windows-Defender