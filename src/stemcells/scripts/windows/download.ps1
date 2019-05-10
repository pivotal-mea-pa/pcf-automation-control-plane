#ps1_sysnative

Param(
  [string][Parameter(Mandatory=$True)]$WindowsManagmentFrameworkURL,
  [string][Parameter(Mandatory=$True)]$VisualStudioURL,
  [string][Parameter(Mandatory=$True)]$NuGetURL,
  [string][Parameter(Mandatory=$True)]$PSWindowsUpdateURL,
  [string][Parameter(Mandatory=$True)]$BoshPsModulesURL,
  [string][Parameter(Mandatory=$True)]$BoshAgentURL,
  [string][Parameter(Mandatory=$True)]$OpenSSHUrl
)

$DownloadPath = "C:\Stemcell-Build\Downloads"

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"

# Wait for internet connectivity
Do {
  Write-Host "Waiting for internet connectivity..."
  try {
    $HTTP_Request = [System.Net.WebRequest]::Create('http://google.com')
    $HTTP_Response = $HTTP_Request.GetResponse()
    $HTTP_Status = [int]$HTTP_Response.StatusCode
    $HTTP_Response.Close()
  } catch {
    $HTTP_Status = 500
  }
} Until ($HTTP_Status -eq 200)

# Enable TLS12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download Windows Management Framework 5.1
Invoke-WebRequest `
  -uri "$WindowsManagmentFrameworkURL" `
  -outfile "$DownloadPath\WindowsManagmentFramework.msu"
Unblock-File "$DownloadPath\WindowsManagmentFramework.msu"

# Download Visual Studio installer
Invoke-WebRequest `
  -uri "$VisualStudioURL" `
  -outfile "$DownloadPath\VisualStudio-Installer.exe"
Unblock-File "$DownloadPath\VisualStudio-Installer.exe"

# Download NuGet
Invoke-WebRequest `
  -uri "$NuGetURL" `
  -outfile "$DownloadPath\NuGet.exe"
Unblock-File "$DownloadPath\NuGet.exe"

# Download PSWindowsUpdate PowerShell NuGet package
Invoke-WebRequest `
  -uri "$PSWindowsUpdateURL" `
  -outfile "$DownloadPath\PSWindowsUpdate.nupkg"
Unblock-File "$DownloadPath\PSWindowsUpdate.nupkg"

# Download Bosh PowerShell modules
Invoke-WebRequest `
  -uri "$BoshPsModulesURL" `
  -outfile "$DownloadPath\Bosh-PSModules.zip"
Unblock-File "$DownloadPath\Bosh-PSModules.zip"

# Download Bosh agent
Invoke-WebRequest `
  -uri "$BoshAgentURL" `
  -outfile "$DownloadPath\Bosh-Agent.zip"
Unblock-File "$DownloadPath\Bosh-Agent.zip"

# Download OpenSSH
Invoke-WebRequest `
  -uri "$OpenSSHUrl" `
  -outfile "$DownloadPath\OpenSSH-Win64.zip"
Unblock-File "$DownloadPath\OpenSSH-Win64.zip"

Stop-Transcript
