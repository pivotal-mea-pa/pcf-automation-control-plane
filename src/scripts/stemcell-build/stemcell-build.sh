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
    packer_builder=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/packer_builder?)
    debug=$(bosh interpolate ${root_dir}/vars.yml \
      --path /stemcell_build/$i/debug?)

    [[ -n $custom_file_upload && $custom_file_upload != null ]] || \
      custom_file_upload=.stembuild/noop.dat
    [[ -n $custom_ps1_script && $custom_ps1_script != null ]] || \
      custom_ps1_script=.stembuild/noop.ps1
    [[ -n $packer_builder && $packer_builder != null ]] || \
      packer_builder=vbox
    [[ -n $debug && $debug != null ]] || \
      debug='false'

    if [[ $debug == true ]]; then
      packer_log=1
      on_error=abort
    else
      packer_log=0
      on_error=cleanup
    fi

    set +u
    build_number=$(eval "echo \$${operating_system}_build_number")
    build_number=${build_number:-0}
    set -u
    version="${bosh_version}.${build_number}"

    iaas_scripts_path=${root_dir}/src/scripts/stemcell-build/${iaas}
    stemcell_image_path=${stemcell_build_path}/${operating_system}

    image_build_name=${operating_system}-stemcell
    stemcell_disk_image=${stemcell_image_path}/stemcell/${image_build_name}

    num_iaas=$(bosh interpolate ${root_dir}/vars.yml --path /stemcell_build/$i/iaas | grep -e "^-" | wc -l)
    for j in $(seq 0 $((num_iaas-1))); do

      iaas=$(bosh interpolate ${root_dir}/vars.yml \
        --path /stemcell_build/$i/iaas/$j/type)

      if [[ ! -e ${stemcell_image_path}/stemcell \
        || $action == clean ]]; then
        rm -fr ${stemcell_image_path}

        mkdir -p ${stemcell_image_path}
        sed "s|###product_key###|${product_key}|g" \
          ${root_dir}/src/stemcells/config/${operating_system}/autounattend.xml \
          > ${stemcell_image_path}/autounattend.xml
        sed -i "s|###admin_password###|${admin_password}|g" \
          ${stemcell_image_path}/autounattend.xml

        provider_specific_vars=""
        [[ ! -e ${iaas_scripts_path}/build-vars-${packer_builder}.sh ]] || \
          source ${iaas_scripts_path}/build-vars-${packer_builder}.sh

        echo "Building base "${version}" of the ${iaas} stemcell for OS '${operating_system}' ..."

        PACKER_LOG=${packer_log} packer build -force \
          -on-error=${on_error} \
          $provider_specific_vars \
          -var "image_build_name=${image_build_name}" \
          -var "vs_download_url=https://s3.eu-central-1.amazonaws.com/mevansam-share/public/vs_community__378995140.1557481685.exe" \
          -var "nuget_download_url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" \
          -var "bosh_ps_modules_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/bosh-psmodules.zip" \
          -var "bosh_agent_download_url=https://github.com/cloudfoundry-incubator/bosh-windows-stemcell-builder/releases/download/${bosh_version}/agent.zip" \
          -var "openssh_win64_download_url=https://github.com/PowerShell/Win32-OpenSSH/releases/download/${openssh_version}/OpenSSH-Win64.zip" \
          -var "custom_file_upload=${custom_file_upload}" \
          -var "custom_ps1_script=${custom_ps1_script}" \
          -var "admin_password=${admin_password}" \
          -var "time_zone=${time_zone}" \
          -var "organization=${organization}" \
          -var "owner=${owner}" \
          -var "product_key=${product_key}" \
          -var "root_dir=${root_dir}" \
          -var "stemcell_build_path=${stemcell_build_path}" \
          -var "debug=${debug}" \
          src/stemcells/packer/${iaas}/${operating_system}-${packer_builder}.json 2>&1 \
          | tee ${root_dir}/build-${iaas}-${operating_system}.log

        # Exit with error if build did no complete successfuly
        cat build-$iaas-${operating_system}.log | grep "Build '.*' finished." 2>&1 >/dev/null

        [[ ! -e ${iaas_scripts_path}/stemcell-build-${packer_builder}.sh ]] || \
          source ${iaas_scripts_path}/stemcell-build-${packer_builder}.sh
      fi

      source ${iaas_scripts_path}/package-stemcell.sh

      [[ $action != test ]] || \
        source ${root_dir}/src/scripts/stemcell-build/test-windows-stemcell.sh
    done
done
