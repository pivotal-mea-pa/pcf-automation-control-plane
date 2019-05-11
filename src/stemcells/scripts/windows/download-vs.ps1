#ps1_sysnative

Param(
  [string][Parameter(Mandatory=$True)]$VisualStudioURL,
  [string][Parameter(Mandatory=$True)]$NuGetURL
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

# Download Visual Studio installer
Write-Output "Downloading Visual Studio installer..."
Invoke-WebRequest `
  -uri "$VisualStudioURL" `
  -outfile "$DownloadPath\VisualStudio-Installer.exe"
Unblock-File "$DownloadPath\VisualStudio-Installer.exe"

# Download NuGet
Write-Output "Downloading NuGet executable..."
Invoke-WebRequest `
  -uri "$NuGetURL" `
  -outfile "$DownloadPath\NuGet.exe"
Unblock-File "$DownloadPath\NuGet.exe"
