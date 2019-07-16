Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"
$ProgressPreference='SilentlyContinue'

$DownloadPath = "C:\Stemcell-Build\Downloads"

# Install VMware Tools
cd $DownloadPath
.\VMware-tools-windows.exe /s /v "/qn reboot=r"
Start-Sleep -Seconds 10
Wait-Process -Name msiexec
