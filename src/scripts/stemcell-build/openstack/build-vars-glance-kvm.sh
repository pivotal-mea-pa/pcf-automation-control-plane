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

provider_specific_vars="-var 'iso_url=${iso_url}' -var 'iso_checksum=${iso_checksum}' -var 'iso_checksum_type=${iso_checksum_type}'"
