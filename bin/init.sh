#!/bin/bash

set -e

iaas=$1
update=$2

root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

source ${root_dir}/src/scripts/common.sh
source ${root_dir}/src/scripts/deploy-bosh.sh

cat << ---EOF > ${root_dir}/.envrc
$iaas_env

export BOSH_ENVIRONMENT='$(bosh interpolate ${root_dir}/vars.yml --path /dns_name)'
export BOSH_CA_CERT='$(bosh interpolate --no-color $creds_path --path /director_ssl/ca)'
export BOSH_CLIENT='admin'
export BOSH_CLIENT_SECRET='$(bosh interpolate --no-color $creds_path --path /admin_password)'

export CREDHUB_SERVER=https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8844
export CREDHUB_CA_CERT='$(bosh interpolate --no-color $creds_path --path /credhub_tls/ca)'
export CREDHUB_CLIENT=credhub-admin
export CREDHUB_SECRET='$(bosh interpolate --no-color $creds_path --path /credhub_admin_client_secret)'

export UAA_TARGET=https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8443
export UAA_ADMIN_CLIENT=\$BOSH_CLIENT
export UAA_ADMIN_CLIENT_SECRET=\$BOSH_CLIENT_SECRET
---EOF

set +e
which direnv 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
  set -e
  direnv allow
fi
