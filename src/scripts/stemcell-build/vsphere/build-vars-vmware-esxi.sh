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

esxi_remote_host=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/esxi_remote_host)
esxi_remote_username=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/esxi_remote_username)
esxi_remote_password=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/esxi_remote_password)
esxi_datastore=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/esxi_datastore)
esxi_vm_network=$(bosh interpolate ${root_dir}/vars.yml \
  --path /stemcell_build/$i/iaas/$j/esxi_vm_network)

iso_url=$(cd ${root_dir}/$(dirname $iso_url) && pwd)/$(basename $iso_url)

provider_specific_vars="-var iso_url=${iso_url}"
provider_specific_vars="${provider_specific_vars} -var iso_checksum=${iso_checksum}"
provider_specific_vars="${provider_specific_vars} -var iso_checksum_type=${iso_checksum_type}"
provider_specific_vars="${provider_specific_vars} -var vmware_tools_download_url=${vmware_tools_url}"
provider_specific_vars="${provider_specific_vars} -var esxi_remote_host=${esxi_remote_host}"
provider_specific_vars="${provider_specific_vars} -var esxi_remote_username=${esxi_remote_username}"
provider_specific_vars="${provider_specific_vars} -var esxi_datastore=${esxi_datastore}"
provider_specific_vars="${provider_specific_vars} -var esxi_vm_network=${esxi_vm_network}"

stemcell_disk_image=${stemcell_image_path}/stemcell/disk.vmdk
stemcell_archive_name="bosh-stemcell-${version}-vsphere-esxi-${operating_system}-go_agent.tgz"
