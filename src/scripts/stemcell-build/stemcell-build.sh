#!/bin/bash

set -eux

stemcell_build_path=${root_dir}/.stembuild
mkdir -p $stemcell_build_path

touch ${stemcell_build_path}/noop.dat
touch ${stemcell_build_path}/noop.ps1

#
# Read build configuration
#

num_stemcell_builds=$(bosh interpolate ${root_dir}/vars.yml --path /stemcell_build | grep -e "^-" | wc -l)
for i in $(seq 0 $((num_stemcell_builds-1))); do
    
    operating_system=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/operating_system)
    product=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/product)
    bosh_version=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/bosh_version)
    openssh_version=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/openssh_version)
    custom_file_upload=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/custom_file_upload?)
    custom_ps1_script=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/custom_ps1_script?)

    if [[ -n $custom_file_upload && $custom_file_upload != null ]]; then
      custom_file_upload=$(cd $(dirname ${root_dir}/${custom_file_upload}) && pwd)/$(basename $custom_file_upload)
    else
      custom_file_upload=${stemcell_build_path}/noop.dat
    fi
    if [[ -n $custom_ps1_script && $custom_ps1_script != null ]]; then
      custom_ps1_script=$(cd $(dirname ${root_dir}/${custom_ps1_script}) && pwd)/$(basename $custom_ps1_script)
    else
      custom_ps1_script=${stemcell_build_path}/noop.ps1
    fi

    set +u
    build_number=$(eval "echo \$${operating_system}_build_number")
    build_number=${build_number:-0}
    set -u

    num_iaas=$(bosh interpolate ${root_dir}/vars.yml --path /stemcell_build/$i/iaas | grep -e "^-" | wc -l)
    for j in $(seq 0 $((num_iaas-1))); do

      iaas=$(bosh interpolate ${root_dir}/vars.yml \
        --path /stemcell_build/$i/iaas/$j/type)

      source ${root_dir}/src/scripts/stemcell-build/build-${iaas}-stemcell.sh
    done
done