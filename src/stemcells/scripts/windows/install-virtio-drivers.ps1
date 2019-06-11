Start-Transcript -path "C:\Stemcell-Build\Logs\build.log" -append
$ErrorActionPreference = "Stop"
$ProgressPreference='SilentlyContinue'

$DownloadPath = "C:\Stemcell-Build\Downloads"
$ScriptsPath = "C:\Stemcell-Build\Scripts"
$TempPath = "C:\Stemcell-Build\Temp"

# Determine Windows version
$OsVersion = [System.Environment]::OSVersion.Version.ToString()

$OsArch = "amd64"
$OsName = ""
if ($osVersion -match "6\.3\.9600\..+") {
  $OsName = "2k12R2"
}
elseif ($osVersion -match "10\.0\..+") {
  $OsName = "2k16"
}
else {
  throw "invalid OS detected"
}

# Mount VirtIO ISO image
$Drive = Mount-DiskImage -ImagePath "$DownloadPath\virtio-win.iso" -PassThru `
  | Get-DiskImage | Get-Volume
$VirtIODriverPath = '{0}:\' -f $Drive.DriveLetter
$CertStorePath = "Cert:\LocalMachine\TrustedPublisher"

Get-ChildItem -Recurse -Include "*.inf" -File "$VirtIODriverPath" | ForEach-Object {

  # Install drivers for amd64 and correct OS
  if ($_.Directory.Name -eq $OsArch -and $_.Directory.Parent.Name -eq $OsName) {
    $DriverName = $_.Directory.Parent.Parent.Name
    $DriverSourceDirectory = $_.Directory
    $DriverInfFile = (Resolve-Path "$DriverSourceDirectory\*.inf").Path

    # Trust the 3rd-party driver certificate.
    $DriverCatPath = $DriverInfFile.Replace('.inf', '.cat')
    $DriverCertPath = "${TempPath}\${DriverName}.cer"
    $Certificate = (Get-AuthenticodeSignature $DriverCatPath).SignerCertificate
    [System.IO.File]::WriteAllBytes($DriverCertPath, $Certificate.Export('Cert'))
    
    Write-Output "Adding driver certificate to TrustedPublisher certificate store:... : $DriverCertPath"
    $CertStore = Get-Item $CertStorePath
    $CertStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]"ReadWrite")
    $CertStore.Add($DriverCertPath)
    $CertStore.Close()

    # Install the driver.
    $ErrorActionPreference = "SilentlyContinue"
    Write-Output "Installing driver $DriverName... : $DriverInfFile"
    if ($OsName -eq "2k16") {
      pnputil /add-driver $DriverInfFile /install
    } else {
      pnputil -i -a $DriverInfFile
    }
    if ($LASTEXITCODE) {
      Write-Output "PnPUtil returned an exit code of $LASTEXITCODE"
    }
    $ErrorActionPreference = "Stop"
  }
}

Write-Output 'Installing the Balloon service...'
&"${VirtIODriverPath}\Balloon\${OsName}\${OsArch}\blnsvr.exe" -i
