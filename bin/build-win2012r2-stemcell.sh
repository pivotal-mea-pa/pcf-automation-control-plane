#!/bin/bash

os=$1

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

# Versions

pswindowsupdate_version="2.1.1.2"
bosh_version="1200.32"
openssh_version="v7.9.0.0p1-Beta"

# Download 

packer build \
  -var "wmf51_download_url=https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu" \
  -var "vs_download_url=https://s3.eu-central-1.amazonaws.com/mevansam-share/public/vs_community__378995140.1557481685.exe" \
  -var "nuget_download_url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" \
  -var "bosh_ps_modules_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/bosh-psmodules.zip" \
  -var "bosh_agent_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/agent.zip" \
  -var "openssh_win64_download_url=https://github.com/PowerShell/Win32-OpenSSH/releases/download/${openssh_version}/OpenSSH-Win64.zip" \
  -var "source_image_name=WindowsServer2012R2-STD" \
  -var "network_uuid=cb8b849f-dfd2-4b18-a1c6-f1b11edca4f4" \
  -var "security_group=pcf" \
  -var "ssh_keypair_name=pcf" \
  -var "image_build_name=windows2012r2-stemcell" \
  -var "root_dir=${root_dir}" \
  src/stemcells/packer/windows2012r2.json 2>&1 \
  | tee ${root_dir}/build-windows2012r2-stemcell.log
