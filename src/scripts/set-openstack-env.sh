#!/bin/bash -eu

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
