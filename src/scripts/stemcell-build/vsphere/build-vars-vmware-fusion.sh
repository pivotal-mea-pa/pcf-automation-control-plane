#!/bin/bash

set -eux

# Read build provider specific variables

iso_url=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iso_url)
iso_checksum=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iso_checksum)
iso_checksum_type=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iso_checksum_type)
vmware_tools_url=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/vmware_tools_url)

iso_url=$(cd ${root_dir}/$(dirname $iso_url) && pwd)/$(basename $iso_url)

provider_specific_vars="-var iso_url=${iso_url}"
provider_specific_vars="${provider_specific_vars} -var iso_checksum=${iso_checksum}"
provider_specific_vars="${provider_specific_vars} -var iso_checksum_type=${iso_checksum_type}"
provider_specific_vars="${provider_specific_vars} -var vmware_tools_download_url=${vmware_tools_url}"

stemcell_disk_image=${stemcell_image_path}/stemcell/disk.vmdk
stemcell_archive_name="bosh-stemcell-${version}-vsphere-esxi-${operating_system}-go_agent.tgz"
