Param(
  [string][Parameter(Mandatory=$True)]$BoshPsModulesURL,
  [string][Parameter(Mandatory=$True)]$BoshAgentURL,
  [string][Parameter(Mandatory=$True)]$OpenSSHUrl
)

$DownloadPath = "C:\Stemcell-Build\Downloads"

Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"
$ProgressPreference='SilentlyContinue'

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

# Download Bosh PowerShell modules
Write-Output "Downloading Bosh PowerShell modules..."
Invoke-WebRequest `
  -uri "$BoshPsModulesURL" `
  -outfile "$DownloadPath\Bosh-PSModules.zip"
Unblock-File "$DownloadPath\Bosh-PSModules.zip"

# Download Bosh agent
Write-Output "Downloading Bosh agent..."
Invoke-WebRequest `
  -uri "$BoshAgentURL" `
  -outfile "$DownloadPath\Bosh-Agent.zip"
Unblock-File "$DownloadPath\Bosh-Agent.zip"

# Download OpenSSH
Write-Output "Downloading OpenSSH for Windows..."
Invoke-WebRequest `
  -uri "$OpenSSHUrl" `
  -outfile "$DownloadPath\OpenSSH-Win64.zip"
Unblock-File "$DownloadPath\OpenSSH-Win64.zip"
