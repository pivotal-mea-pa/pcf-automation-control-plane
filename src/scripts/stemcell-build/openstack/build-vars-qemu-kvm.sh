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

provider_specific_vars="-var iso_url=${iso_url} -var iso_checksum=${iso_checksum} -var iso_checksum_type=${iso_checksum_type}"
stemcell_disk_image=${stemcell_image_path}/stemcell/${image_build_name}

# Although image is QCOW2 we need to name the stemcell file with
# post fix "-raw.tgz" as otherwise Ops Manager rejects the file.
stemcell_archive_name="bosh-stemcell-${version}-openstack-kvm-${operating_system}-go_agent-raw.tgz"
