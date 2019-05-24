#!/bin/bash

set -eux

# Read IaaS specific variables

source_image_name=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/source_image_name)
network_uuid=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/network_uuid)
security_group=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/security_group)
ssh_keypair_name=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/ssh_keypair_name)

version="${bosh_version}.${build_number}"
stemcell_archive_name="bosh-stemcell-${version}-openstack-kvm-${operating_system}-go_agent-raw.tgz"

if [[ $action == clean ]]; then

  # Delete packer volumes
  for i in $(openstack --insecure volume list | awk '/ packer_/{ print $2 }'); do
    openstack --insecure volume delete $i
  done
  # Delete base build images
  for i in $(openstack --insecure image list | awk "/ ${operating_system}-stemcell/{ print \$2 }"); do
    openstack --insecure image delete $i
  done

  rm -f ${stemcell_build_path}/${stemcell_archive_name}
fi

if [[ ! -e ${stemcell_build_path}/${stemcell_archive_name} ]]; then

  echo "Building version "$version" of the OpenStack stemcell for OS '${operating_system}' ..."

  stemcell_image_id=$(openstack --insecure image list | awk "/ ${operating_system}-stemcell-base /{ print \$2 }")
  if [[ -z $stemcell_image_id ]]; then
    packer build \
      -var "vs_download_url=https://s3.eu-central-1.amazonaws.com/mevansam-share/public/vs_community__378995140.1557481685.exe" \
      -var "nuget_download_url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" \
      -var "bosh_ps_modules_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/bosh-psmodules.zip" \
      -var "bosh_agent_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/agent.zip" \
      -var "openssh_win64_download_url=https://github.com/PowerShell/Win32-OpenSSH/releases/download/${openssh_version}/OpenSSH-Win64.zip" \
      -var "source_image_name=$source_image_name" \
      -var "network_uuid=$network_uuid" \
      -var "security_group=$security_group" \
      -var "ssh_keypair_name=$ssh_keypair_name" \
      -var "image_build_name=${operating_system}-stemcell-base" \
      -var "custom_file_upload=${custom_file_upload}" \
      -var "custom_ps1_script=${custom_ps1_script}" \
      -var "root_dir=${root_dir}" \
      src/stemcells/packer/openstack/${operating_system}-base.json 2>&1 \
      | tee ${root_dir}/build-openstack-${operating_system}-base.log

    # Exit with error if build did no complete successfuly
    cat build-openstack-${operating_system}-base.log | grep "Build 'openstack' finished." 2>&1 >/dev/null
  fi

  stemcell_image_name="${operating_system}-stemcell_$(date "+%Y%m%d-%H%M%S")"
  packer build \
    -var "source_image_name=${operating_system}-stemcell-base" \
    -var "network_uuid=$network_uuid" \
    -var "security_group=$security_group" \
    -var "ssh_keypair_name=$ssh_keypair_name" \
    -var "image_build_name=$stemcell_image_name" \
    -var "root_dir=${root_dir}" \
    src/stemcells/packer/openstack/${operating_system}-stemcell.json 2>&1 \
    | tee ${root_dir}/build-openstack-${operating_system}-stemcell.log

  # Exit with error if build did no complete successfuly
  cat build-openstack-win2012r2-stemcell.log | grep "Build 'openstack' finished." 2>&1 >/dev/null

  pushd ${stemcell_build_path}
  rm -f ${stemcell_archive_name}

  stemcell_image_id=$(openstack --insecure image list | awk "/ $stemcell_image_name /{ print \$2 }")
  glance --insecure image-download --progress \
    --file ${stemcell_image_name}.img "${stemcell_image_id}" 2>/dev/null

  qemu-img convert -p -f raw -O qcow2 ${stemcell_image_name}.img root.img
  tar czf image root.img
  rm -f *.img

  image_sha=$(sha1sum image | awk '{ print $1 }')
  version=${bosh_version}.${build_number}
  echo "---
  name: bosh-openstack-kvm-${operating_system}-go_agent
  version: '$version'
  bosh_protocol: 1
  api_version: 2
  sha1: '$image_sha'
  operating_system: ${operating_system}
  stemcell_formats:
  - openstack-qcow2
  cloud_properties:
    name: bosh-openstack-kvm-${operating_system}-go_agent
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
  tar -czf ${stemcell_archive_name} stemcell.MF image
  rm -f stemcell.MF image 

  popd
else
  echo "OpenStack stemcell version '$version' for OS '${operating_system}' has been built ..."
fi

[[ $action != test ]] || \
  source ${root_dir}/src/scripts/stemcell-build/test-windows-stemcell.sh
