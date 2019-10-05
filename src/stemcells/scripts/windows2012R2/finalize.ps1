Param(
  [string][Parameter(Mandatory=$True)]$IaaS,
  [string][Parameter(Mandatory=$True)]$NewPassword,
  [string][Parameter(Mandatory=$True)]$TimeZone,
  [string][Parameter(Mandatory=$True)]$Organization,
  [string][Parameter(Mandatory=$True)]$Owner,
  [string][Parameter(Mandatory=$True)]$ProductKey
)

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"
$ProgressPreference='SilentlyContinue'

$ScriptsPath = "C:\Stemcell-Build\Scripts"
$DownloadPath = "C:\Stemcell-Build\Downloads"

# Function to create registry path
function New-Directory($path) {
  $p, $components = $path -split '[\\/]'
  $components | ForEach-Object {
      $p = "$p\$_"
      if (!(Test-Path $p)) {
          New-Item -ItemType Directory $p | Out-Null
      }
  }
  $path
}

New-Item "C:\Users\vcap" -ItemType Directory
Write-Output "Installing Bosh agent..."
Install-Agent -IaaS $IaaS -agentZipPath "$DownloadPath\Bosh-Agent.zip"
Write-Output "Installing SSH service..."
Install-SSHD -SSHZipFile "$DownloadPath\OpenSSH-Win64.zip"

# Allow NTP Sync
Write-Output "Allowing NTP Sync..."
Set-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" `
  -Name "MaxNegPhaseCorrection" -Value 0xFFFFFFFF -Type DWord `
  -Force -Verbose
Set-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" `
  -Name "MaxPosPhaseCorrection" -Value 0xFFFFFFFF -Type DWord `
  -Force -Verbose

# Enable meltdown mitigation
Write-Output "Enabling meltdown mitigation..."
New-ItemProperty `
  -Path (New-Directory("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management")) `
  -Name "FeatureSettingsOverride" -Value 0 -PropertyType DWord `
  -Force -Verbose
New-ItemProperty `
  -Path (New-Directory("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management")) `
  -Name "FeatureSettingsOverrideMask" -Value 3 -PropertyType DWord `
  -Force -Verbose
New-ItemProperty `
  -Path (New-Directory("HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization")) `
  -Name "MinVmVersionForCpuBasedMitigations" -Value "1.0" -PropertyType String `
  -Force -Verbose
New-ItemProperty `
  -Path (New-Directory("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\QualityCompat")) `
  -Name "cadca5fe-87d3-4b96-b7fb-a231484277cc" -Value 0 -PropertyType DWord `
  -Force -Verbose

# Set Administrator password
Write-Output "Setting admin password..."
Net User "Administrator" "$NewPassword" /logonpasswordchg:no

# Delete AutoLogon User
Remove-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
  -Name "AutoAdminLogon" -Force -Verbose

# Clean up
Write-Output "Optimizing disk..."
Optimize-Disk
Write-Output "Compressing disk..."
Compress-Disk

Write-Output "Protecting CFCell..."
Protect-CFCell

# Re-enable RDP
Set-ItemProperty `
  -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
  -Name "fDenyTSConnections" -Value 0 -Type DWord -Verbose
Enable-NetFirewallRule `
  -DisplayGroup "Remote Desktop" -Verbose
Get-Service `
  | Where-Object {$_.Name -eq "Termservice" } `
  | Set-Service -StartupType Automatic -Verbose

# Create Unattend - copied from BOSH.Sysprep module
Write-Output "Creating unattend.xml for sysprep..."
$UnattendPath = Join-Path $ScriptsPath "unattend.xml"

$ProductKeyXML=""
if ($ProductKey -ne "") {
  $ProductKeyXML="<ProductKey>$ProductKey</ProductKey>"
}

$OrganizationXML="<RegisteredOrganization />"
if ($Organization -ne "" -and $Organization -ne $null) {
  $OrganizationXML="<RegisteredOrganization>$Organization</RegisteredOrganization>"
}

$OwnerXML="<RegisteredOwner />"
if ($Owner -ne "" -and $Owner -ne $null) {
  $OwnerXML="<RegisteredOwner>$Owner</RegisteredOwner>"
}

$PostUnattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
<settings pass="specialize">
  <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    <OEMInformation>
      <HelpCustomized>false</HelpCustomized>
    </OEMInformation>
    <ComputerName>*</ComputerName>
    <TimeZone>$TimeZone</TimeZone>
    $ProductKeyXML
    $OrganizationXML
    $OwnerXML
  </component>
  <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    <DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
  </component>
  <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-OutOfBoxExperience" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    <DoNotOpenInitialConfigurationTasksAtLogon>true</DoNotOpenInitialConfigurationTasksAtLogon>
  </component>
  <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
    <SkipAutoActivation>true</SkipAutoActivation>
  </component>
  <component name="Microsoft-Windows-NetBT" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <Interfaces>
          <Interface wcm:action="add">
              <NetbiosOptions>2</NetbiosOptions>
              <Identifier>Ethernet0</Identifier>
          </Interface>
      </Interfaces>
  </component>
</settings>
<settings pass="generalize">
  <component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <PersistAllDeviceInstalls>false</PersistAllDeviceInstalls>
    <DoNotCleanUpNonPresentDevices>false</DoNotCleanUpNonPresentDevices>
  </component>
</settings>
<settings pass="oobeSystem">
  <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <InputLocale>en-US</InputLocale>
    <SystemLocale>en-US</SystemLocale>
    <UILanguage>en-US</UILanguage>
    <UserLocale>en-US</UserLocale>
  </component>
  <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <OOBE>
      <HideEULAPage>true</HideEULAPage>
      <ProtectYourPC>3</ProtectYourPC>
      <NetworkLocation>Work</NetworkLocation>
      <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
    </OOBE>
    <OOBE>
    <TimeZone>$TimeZone</TimeZone>
  </component>
</settings>
</unattend>
"@

Write-Output "Writing unattend.xml to $UnattendPath"
Out-File -FilePath $UnattendPath -InputObject $PostUnattend -Encoding utf8

# Exec sysprep and shutdown
Write-Output "Invoking Sysprep for..."

C:/windows/system32/sysprep/sysprep.exe `
  /quiet /generalize /oobe /quit `
  /unattend:"$UnattendPath"
