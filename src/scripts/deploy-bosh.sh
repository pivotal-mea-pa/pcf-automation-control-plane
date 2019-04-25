#!/bin/bash

apply_local_download_ops_rules=""
if [[ -n $downloads_dir && $downloads_dir != null ]]; then
  apply_local_download_ops_rules="-o ${{ops_file_path}}/bosh/op-local-releases.yml -o ${{ops_file_path}}/bosh/op-local-${iaas}-release.yml"
fi

if [[ -n $update \
  || ! -e $state_path \
  || ! -e $creds_path ]]; then

  bosh create-env \
    ${bosh_deployment_home}/bosh.yml \
    -o ${bosh_deployment_home}/uaa.yml \
    -o ${bosh_deployment_home}/credhub.yml \
    -o ${bosh_deployment_home}/${iaas}/cpi.yml \
    $apply_local_download_ops_rules \
    -o ${ops_file_path}/bosh/op-cpi-${iaas}.yml \
    -o ${ops_file_path}/bosh/op-network.yml \
    -o ${ops_file_path}/bosh/op-bosh-vm.yml \
    -o ${ops_file_path}/bosh/op-uaa.yml \
    -o ${ops_file_path}/bosh/op-credhub.yml \
    -o ${ops_file_path}/bosh/op-uaa-url.yml \
    --vars-store=${creds_path} \
    --vars-file=${root_dir}/vars.yml \
    --var-file=private_key=${keys_path}/pcf.pem \
    --state=$state_path
fi

bosh interpolate \
  ${bosh_deployment_home}/bosh.yml \
  -o ${bosh_deployment_home}/uaa.yml \
  -o ${bosh_deployment_home}/credhub.yml \
  -o ${bosh_deployment_home}/${iaas}/cpi.yml \
  $apply_local_download_ops_rules \
  -o ${ops_file_path}/bosh/op-cpi-${iaas}.yml \
  -o ${ops_file_path}/bosh/op-network.yml \
  -o ${ops_file_path}/bosh/op-bosh-vm.yml \
  -o ${ops_file_path}/bosh/op-uaa.yml \
  -o ${ops_file_path}/bosh/op-credhub.yml \
  -o ${ops_file_path}/bosh/op-uaa-url.yml \
  --vars-file=${root_dir}/vars.yml \
  --var-file=private_key=${keys_path}/pcf.pem > $bosh_manifest

set +e
read -r -d '' iaas_env << EOV
export OS_AUTH_URL='$(bosh interpolate --no-color $bosh_manifest --path /cloud_provider/properties/openstack/auth_url)'
export OS_PROJECT_DOMAIN_NAME='$(bosh interpolate --no-color $bosh_manifest --path /cloud_provider/properties/openstack/domain)'
export OS_PROJECT_NAME='$(bosh interpolate --no-color $bosh_manifest --path /cloud_provider/properties/openstack/project)'
export OS_USER_DOMAIN_NAME='$(bosh interpolate --no-color $bosh_manifest --path /cloud_provider/properties/openstack/domain)'
export OS_USERNAME='$(bosh interpolate --no-color $bosh_manifest --path /cloud_provider/properties/openstack/username)'
export OS_PASSWORD='$(bosh interpolate --no-color $bosh_manifest --path /cloud_provider/properties/openstack/api_key)'
EOV
set -e