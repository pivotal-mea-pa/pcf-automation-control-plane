#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

# Update windows
Import-Module PSWindowsUpdate

$Script = {ipmo PSWindowsUpdate; Get-WUInstall -AcceptAll -AutoReboot `
  | Out-File -Append C:\Temp\Logs\stemcell-config.log}
Invoke-WUInstall -ComputerName $env:computername -Script $Script

Install-WindowsUpdate -ComputerName $env:computername -Install -MicrosoftUpdate -AcceptAll -IgnoreReboot -Verbose

Stop-Transcript
