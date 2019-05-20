#!/bin/bash

action=$1

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

# Inputs - need to be externalized
build_number=0
source_image_name="WindowsServer2012R2-STD"
network_uuid=cb8b849f-dfd2-4b18-a1c6-f1b11edca4f4
security_group=pcf
ssh_keypair_name=pcf

# Versions

bosh_version="1200.32"
openssh_version="v7.9.0.0p1-Beta"

if [[ $action == clean ]]; then

  # Delete images

  openstack --insecure volume list | \
    awk '/ packer_/{ print $2 }' | \
    xargs openstack --insecure volume delete

  openstack --insecure image list | \
    awk '/ win2012r2-stemcell/{ print $2 }' | \
    xargs openstack --insecure image delete
fi

stemcell_image_id=$(openstack --insecure image list | awk '/ win2012r2-stemcell-base /{ print $2 }')
if [[ -z $stemcell_image_id ]]; then
  packer build \
    -var "wmf51_download_url=https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu" \
    -var "vs_download_url=https://s3.eu-central-1.amazonaws.com/mevansam-share/public/vs_community__378995140.1557481685.exe" \
    -var "nuget_download_url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" \
    -var "bosh_ps_modules_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/bosh-psmodules.zip" \
    -var "bosh_agent_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/agent.zip" \
    -var "openssh_win64_download_url=https://github.com/PowerShell/Win32-OpenSSH/releases/download/${openssh_version}/OpenSSH-Win64.zip" \
    -var "source_image_name=$source_image_name" \
    -var "network_uuid=$network_uuid" \
    -var "security_group=$security_group" \
    -var "ssh_keypair_name=$ssh_keypair_name" \
    -var "image_build_name=win2012r2-stemcell-base" \
    -var "root_dir=${root_dir}" \
    src/stemcells/packer/openstack/win2012r2-base.json 2>&1 \
    | tee ${root_dir}/build-openstack-win2012r2-base.log

  # Exit with error if build did no complete successfuly
  cat build-openstack-win2012r2-base.log | grep "Build 'openstack' finished." 2>&1 >/dev/null
fi

stemcell_image_name="win2012r2-stemcell_$(date "+%Y%m%d-%H%M%S")"
packer build \
  -var "source_image_name=win2012r2-stemcell-base" \
  -var "network_uuid=$network_uuid" \
  -var "security_group=$security_group" \
  -var "ssh_keypair_name=$ssh_keypair_name" \
  -var "image_build_name=$stemcell_image_name" \
  -var "root_dir=${root_dir}" \
  src/stemcells/packer/openstack/win2012r2-stemcell.json 2>&1 \
  | tee ${root_dir}/build-openstack-win2012r2-stemcell.log

# Exit with error if build did no complete successfuly
cat build-openstack-win2012r2-stemcell.log | grep "Build 'openstack' finished." 2>&1 >/dev/null

rm -fr ${root_dir}/.stembuild
mkdir -p ${root_dir}/.stembuild
pushd ${root_dir}/.stembuild

stemcell_image_id=$(openstack --insecure image list | awk "/ $stemcell_image_name /{ print \$2 }")
glance --insecure image-download --progress \
  --file ${stemcell_image_name}.img "${stemcell_image_id}" 2>/dev/null

qemu-img convert -p -f raw -O qcow2 ${stemcell_image_name}.img root.img
tar czf image root.img
rm -f *.img

image_sha=$(sha1sum image | awk '{ print $1 }')
version=${bosh_version}.${build_number}
echo "---
name: bosh-openstack-kvm-windows2016-go_agent
version: '$version'
bosh_protocol: 1
api_version: 2
sha1: '$image_sha'
operating_system: windows2016
stemcell_formats:
- openstack-qcow2
cloud_properties:
  name: bosh-openstack-kvm-windows2016-go_agent
  version: '$version'
  infrastructure: openstack
  hypervisor: kvm
  disk: 35840
  disk_format: qcow2
  container_format: bare
  os_type: windows
  architecture: x86_64
  auto_disk_config: true" > stemcell.MF

# Although image is QCOW2 we need to name the stemcell file with
# post fix "-raw.tgz" as otherwise Ops Manager rejects the file.
tar -czf bosh-stemcell-${version}-openstack-kvm-windows2016-go_agent-raw.tgz stemcell.MF image
rm -f stemcell.MF image 

popd