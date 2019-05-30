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

stemcell_vmdk_path=${stemcell_build_path}/${operating_system}/stemcell/${operating_system}-stemcell-disk001.vmdk
stemcell_archive_name="bosh-stemcell-${version}-openstack-kvm-${operating_system}-go_agent-raw.tgz"
# if [[ ! -e $stemcell_archive_name || $action == clean ]]; then
#   rm -f ${stemcell_build_path}/${stemcell_archive_name}

#   if [[ ! -e $stemcell_vmdk_path ]]; then
#     echo "Unable to find VMDK file of built stemcell. Please do a clean rebuild."
#     exit 1
#   fi

#   pushd ${stemcell_build_path}
#   rm -f ${stemcell_archive_name}

#   qemu-img convert -p -f vmdk -O qcow2 ${stemcell_vmdk_path} root.img
#   exit 1

#   tar czf image root.img
#   rm -f *.img

#   image_sha=$(sha1sum image | awk '{ print $1 }')
#   version=${bosh_version}.${build_number}
#   echo "---
#   name: bosh-openstack-kvm-${operating_system}-go_agent
#   version: '$version'
#   bosh_protocol: 1
#   api_version: 2
#   sha1: '$image_sha'
#   operating_system: ${operating_system}
#   stemcell_formats:
#   - openstack-qcow2
#   cloud_properties:
#     name: bosh-openstack-kvm-${operating_system}-go_agent
#     version: '$version'
#     infrastructure: openstack
#     hypervisor: kvm
#     disk: 35840
#     disk_format: qcow2
#     container_format: bare
#     os_type: windows
#     architecture: x86_64
#     auto_disk_config: true" > stemcell.MF

#   # Although image is QCOW2 we need to name the stemcell file with
#   # post fix "-raw.tgz" as otherwise Ops Manager rejects the file.
#   tar -czf ${stemcell_archive_name} stemcell.MF image
#   rm -f stemcell.MF image 

#   popd
# else
#   echo "OpenStack stemcell version '$version' for OS '${operating_system}' has been built ..."
# fi

# [[ $action != test ]] || \
#   source ${root_dir}/src/scripts/stemcell-build/test-windows-stemcell.sh
