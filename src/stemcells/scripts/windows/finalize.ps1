#ps1_sysnative

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

Write-Output "Optimizing disk..."
Optimize-Disk
Write-Output "Compressing disk..."
Compress-Disk
Write-Output "Protecting CFCell..."
Protect-CFCell
