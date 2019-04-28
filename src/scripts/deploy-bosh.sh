#!/bin/bash

apply_local_download_ops_rules=""
if [[ -n $downloads_dir && $downloads_dir != null ]]; then
  apply_local_download_ops_rules="-o ${{ops_file_path}}/bosh/op-local-releases.yml -o ${{ops_file_path}}/bosh/op-local-${iaas}-release.yml"
fi

apply_branding_ops_rules=""
if [[ "$(bosh interpolate ${root_dir}/vars.yml --path /login_branding_company_name)" != "null" ]]; then
  apply_branding_ops_rules="-o ${ops_file_path}/bosh/op-uaa-branding.yml"
fi

bosh interpolate \
  ${bosh_deployment_home}/bosh.yml \
  -o ${bosh_deployment_home}/uaa.yml \
  -o ${bosh_deployment_home}/credhub.yml \
  -o ${bosh_deployment_home}/${iaas}/cpi.yml \
  $apply_local_download_ops_rules \
  $apply_branding_ops_rules \
  -o ${ops_file_path}/bosh/op-cpi-${iaas}.yml \
  -o ${ops_file_path}/bosh/op-network.yml \
  -o ${ops_file_path}/bosh/op-bosh-vm.yml \
  -o ${ops_file_path}/bosh/op-uaa.yml \
  -o ${ops_file_path}/bosh/op-credhub.yml \
  -o ${ops_file_path}/bosh/op-uaa-url.yml \
  -l ${root_dir}/vars.yml \
  --var-file=private_key=${keys_path}/pcf.pem > $bosh_manifest

if [[ $action != create-manifests-only
  && ( $action == deploy \
    || ! -e $state_path \
    || ! -e $creds_path ) ]]; then

  bosh create-env $bosh_manifest \
    --var-file=private_key=${keys_path}/pcf.pem \
    --vars-store=${creds_path} \
    --state=$state_path
fi

bosh interpolate \
  $manifests_file_path/cloud-config.yml \
  -o ${ops_file_path}/cloud-config/op-${iaas}.yml > $cloud_config

# Source IAAS environment variables to 
# added to the .envrc environment file
[[ ! -e ${root_dir}/src/scripts/set-${iaas}-env.sh ]] || \
  source ${root_dir}/src/scripts/set-${iaas}-env.sh

source ${root_dir}/src/scripts/set-env-vars.sh
source ${root_dir}/src/scripts/set-credhub-vars.sh

upload_ubuntu_stemcell_sha1=$(bosh interpolate ${root_dir}/vars.yml --path /ubuntu_sha1)
if [[ "$upload_ubuntu_stemcell_sha1" != "$ubuntu_stemcell_sha1" ]]; then
  bosh -n upload-stemcell \
    --sha1 $upload_ubuntu_stemcell_sha1 \
    $(bosh interpolate ${root_dir}/vars.yml --path /ubuntu_stemcell)

  (grep "^ubuntu_stemcell_sha1=" .state/checksums 2>&1 >/dev/null \
      && sed -i "s|^ubuntu_stemcell_sha1=.*|ubuntu_stemcell_sha1=${upload_ubuntu_stemcell_sha1}|" .state/checksums) \
  || echo -e "ubuntu_stemcell_sha1=${upload_ubuntu_stemcell_sha1}" >> .state/checksums  
fi

bosh -n update-cloud-config \
  $cloud_config \
  -l ${root_dir}/vars.yml
