$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null
Start-Transcript -path "C:\Temp\Logs\stemcell-config.log" -append
$ErrorActionPreference = "Stop"

# Cloudbase-Init Script to set password for administrator of the stemcell
New-Item -ItemType "file" -path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\setup-admin.ps1" -Value @'
$NewPassword = "P1v0t@l_DED"
$AdminUser = [ADSI]"WinNT://${env:computername}/Administrator,User"
$AdminUser.SetPassword($NewPassword)
$AdminUser.passwordExpired = 0
$AdminUser.setinfo()
'@

New-Item -ItemType "file" -path "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml" -Force -Value @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="generalize">
    <component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <PersistAllDeviceInstalls>true</PersistAllDeviceInstalls>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <OOBE>
    <HideEULAPage>true</HideEULAPage>
    <NetworkLocation>Work</NetworkLocation>
    <ProtectYourPC>1</ProtectYourPC>
    <SkipMachineOOBE>true</SkipMachineOOBE>
    <SkipUserOOBE>true</SkipUserOOBE>
  </OOBE>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <RunSynchronous>
    <RunSynchronousCommand wcm:action="add">
      <Order>1</Order>
      <Path>"C:\Program Files\Cloudbase Solutions\Cloudbase-Init\Python\Scripts\cloudbase-init.exe" --config-file "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf"</Path>
      <Description>Run Cloudbase-Init to set the hostname</Description>
      <WillReboot>Never</WillReboot>
    </RunSynchronousCommand>
    <RunSynchronousCommand wcm:action="add">
      <Order>2</Order>
      <Path>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\setup-admin.ps1"</Path>
      <Description>password</Description>
      <WillReboot>Always</WillReboot>
    </RunSynchronousCommand>
  </RunSynchronous>
    </component>
  </settings>
</unattend>
"@

# Write-Output "Optimizing disk..."
# Optimize-Disk
# Write-Output "Compressing disk..."
# Compress-Disk

Write-Output "Executing Sysprep..."
C:\Windows\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet /shutdown `
  /unattend:'C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml'

Stop-Transcript
