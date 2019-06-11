#!/bin/bash

set -eux

# Read build provider specific variables

iso_url=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iso_url)
iso_checksum=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iso_checksum)
iso_checksum_type=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iso_checksum_type)

iso_url=$(cd ${root_dir}/$(dirname $iso_url) && pwd)/$(basename $iso_url)

provider_specific_vars="-var 'iso_url=${iso_url}' -var 'iso_checksum=${iso_checksum}' -var 'iso_checksum_type=${iso_checksum_type}'"
