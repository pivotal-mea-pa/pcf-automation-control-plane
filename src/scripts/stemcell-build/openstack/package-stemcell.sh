#!/bin/bash

set -eux

# Read IaaS specific variables

if [[ ! -e ${stemcell_build_path}/${stemcell_archive_name} \
  || $action == clean ]]; then
  rm -f ${stemcell_build_path}/${stemcell_archive_name}

  if [[ ! -e $stemcell_disk_image ]]; then
    echo "Unable to find disk file for stemcell. Please do a clean rebuild."
    exit 1
  fi

  pushd ${stemcell_build_path}
  rm -f ${stemcell_archive_name}

  qemu-img convert -p -c -O qcow2 ${stemcell_disk_image} root.img

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

  tar -czf ${stemcell_archive_name} stemcell.MF image
  rm -f stemcell.MF image 

  popd
else
  echo "OpenStack stemcell version '$version' for OS '${operating_system}' exists ..."
fi
