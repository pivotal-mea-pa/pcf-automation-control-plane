#ps1_sysnative

Param(
  [string][Parameter(Mandatory=$True)]$WindowsManagmentFrameworkURL
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
Write-Output "Downloading Windows Management Framework 5.1..."
Invoke-WebRequest `
  -uri "$WindowsManagmentFrameworkURL" `
  -outfile "$DownloadPath\WindowsManagmentFramework.msu"
Unblock-File "$DownloadPath\WindowsManagmentFramework.msu"
