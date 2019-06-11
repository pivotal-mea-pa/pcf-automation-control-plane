#!/bin/bash

set -eux

# Read build provider specific variables

source_image_name=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/source_image_name)
network_uuid=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/network_uuid)
security_group=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/security_group)
ssh_keypair_name=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/ssh_keypair_name)

provider_specific_vars="-var source_image_name=${source_image_name} -var network_uuid=${network_uuid} -var security_group=${security_group} -var ssh_keypair_name=${ssh_keypair_name}"

# Delete packer volumes
for i in $(openstack --insecure volume list | awk '/ packer_/{ print $2 }'); do
  openstack --insecure volume delete $i
done
# Delete build images
for i in $(openstack --insecure image list | awk "/ ${image_build_name} /{ print \$2 }"); do
  openstack --insecure image delete $i
done
