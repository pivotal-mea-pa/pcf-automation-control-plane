Param(
  [string][Parameter(Mandatory=$True)]$Message,
  [string][Parameter(Mandatory=$True)]$DownloadURL,
  [string][Parameter(Mandatory=$True)]$OutputFile
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

# Download file
Write-Output @"
$Message
  <== $DownloadURL
  ==> $DownloadPath\$OutputFile
"@

Invoke-WebRequest `
  -uri "$DownloadURL" `
  -outfile "$DownloadPath\$OutputFile"
if ($LASTEXITCODE) {
  throw "Failed with exit code $LASTEXITCODE"
}
  
Unblock-File "$DownloadPath\$OutputFile"
