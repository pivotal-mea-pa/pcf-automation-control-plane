Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

# Update windows
Import-Module PSWindowsUpdate
Install-WindowsUpdate -ComputerName $env:computername -Install -MicrosoftUpdate -AcceptAll -IgnoreReboot -Verbose
