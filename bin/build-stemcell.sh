#!/bin/bash

os=$1

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

packer build \
  -var "source_image_name=WindowsServer2012R2-STD" \
  -var "network_uuid=cb8b849f-dfd2-4b18-a1c6-f1b11edca4f4" \
  -var "security_group=pcf" \
  -var "ssh_keypair_name=pcf" \
  -var "image_build_name=windows2012r2-stemcell" \
  -var "root_dir=${root_dir}" \
  src/stemcells/packer/windows2012r2.json 2>&1 \
  | tee ${root_dir}/build-windows2012r2-stemcell.log
