Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

$ScriptPath = "C:\Stemcell-Build\Scripts"

# Enable windows update service to be 
# manually triggered as it gets disabled 
# by Bosh agent install script
SC.exe config wuauserv start=demand

# Configure task to run windows update
$User = "NT AUTHORITY\SYSTEM"
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "$ScriptPath\windows-update.ps1"
Register-ScheduledTask -TaskName "RunWindowsUpdate" -User $User -Action $Action -RunLevel Highest -Force

Stop-Transcript
Start-ScheduledTask -TaskName "RunWindowsUpdate"
