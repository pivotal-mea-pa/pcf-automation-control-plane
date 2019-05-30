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
    iso_url=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/iso_url)
    iso_checksum=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/iso_checksum)
    iso_checksum_type=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/iso_checksum_type)
    bosh_version=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/bosh_version)
    openssh_version=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/openssh_version)
    custom_file_upload=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/custom_file_upload?)
    custom_ps1_script=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/custom_ps1_script?)
    admin_password=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/admin_password?)
    time_zone=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/time_zone?)
    organization=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/organization?)
    owner=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/owner?)
    product_key=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/product_key?)

    iso_url=$(cd ${root_dir}/$(dirname $iso_url) && pwd)/$(basename $iso_url)

    [[ -n $custom_file_upload && $custom_file_upload != null ]] || \
      custom_file_upload=.stembuild/noop.dat
    [[ -n $custom_ps1_script && $custom_ps1_script != null ]] || \
      custom_ps1_script=.stembuild/noop.ps1

    set +u
    build_number=$(eval "echo \$${operating_system}_build_number")
    build_number=${build_number:-0}
    set -u

    num_iaas=$(bosh interpolate ${root_dir}/vars.yml --path /stemcell_build/$i/iaas | grep -e "^-" | wc -l)
    for j in $(seq 0 $((num_iaas-1))); do

      iaas=$(bosh interpolate ${root_dir}/vars.yml \
        --path /stemcell_build/$i/iaas/$j/type)

      version="${bosh_version}.${build_number}"
      stemcell_base_ovf_file=${stemcell_build_path}/${operating_system}/stemcell/${operating_system}-stemcell.ovf

      if [[ ! -e $stemcell_base_ovf_file || $action == clean ]]; then
        rm -fr ${stemcell_build_path}/${operating_system}

        mkdir -p ${stemcell_build_path}/${operating_system}
        sed "s|###product_key###|$product_key|" ${root_dir}/src/stemcells/config/${operating_system}/autounattend.xml \
          > ${stemcell_build_path}/${operating_system}/autounattend.xml

        echo "Building base "$version" of the $iaas stemcell for OS '${operating_system}' ..."

        packer build \
          -var "iso_url=${iso_url}" \
          -var "iso_checksum=${iso_checksum}" \
          -var "iso_checksum_type=${iso_checksum_type}" \
          -var "image_build_name=${operating_system}-stemcell" \
          -var "vs_download_url=https://s3.eu-central-1.amazonaws.com/mevansam-share/public/vs_community__378995140.1557481685.exe" \
          -var "nuget_download_url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" \
          -var "bosh_ps_modules_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/bosh-psmodules.zip" \
          -var "bosh_agent_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/agent.zip" \
          -var "openssh_win64_download_url=https://github.com/PowerShell/Win32-OpenSSH/releases/download/${openssh_version}/OpenSSH-Win64.zip" \
          -var "custom_file_upload=${custom_file_upload}" \
          -var "custom_ps1_script=${custom_ps1_script}" \
          -var "admin_password=$admin_password" \
          -var "time_zone=$time_zone" \
          -var "organization=$organization" \
          -var "owner=$owner" \
          -var "product_key=$product_key" \
          -var "root_dir=${root_dir}" \
          -var "debug=true" \
          src/stemcells/packer/$iaas/${operating_system}.json 2>&1 \
          | tee ${root_dir}/build-$iaas-${operating_system}.log

        # Exit with error if build did no complete successfuly
        cat build-$iaas-${operating_system}.log | grep "Build '$iaas' finished." 2>&1 >/dev/null
      fi

      source ${root_dir}/src/scripts/stemcell-build/build-${iaas}-stemcell.sh
    done
done
