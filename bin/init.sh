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
export BOSH_CA_CERT='$(bosh interpolate --no-color $creds_path --path /default_ca/ca)'
export BOSH_CLIENT='admin'
export BOSH_CLIENT_SECRET='$(bosh interpolate --no-color $creds_path --path /admin_password)'

export CREDHUB_SERVER=https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8844
export CREDHUB_CA_CERT='$BOSH_CA_CERT'
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

which credhub 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
  set -e
  credhub login

  credhub set -n "/cp/default_ca" -t certificate \
    -r "$(bosh interpolate --no-color $creds_path --path /default_ca/ca)" \
    -c "$(bosh interpolate --no-color $creds_path --path /default_ca/certificate)" \
    -p "$(bosh interpolate --no-color $creds_path --path /default_ca/private_key)"

  credhub set -n "/cp/bosh_host" -t value \
    -v "$(bosh interpolate ${root_dir}/vars.yml --path /dns_name)"    
  credhub set -n "/cp/uaa_url" -t value \
    -v "https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8443"

  credhub set -n "/cp/admin_client" -t value \
    -v "admin"
  credhub set -n "/cp/admin_client_secret" -t value \
    -v "$(bosh interpolate --no-color $creds_path --path /admin_password)"

  credhub set -n "/cp/credhub_url" -t value \
    -v "https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8844"
  credhub set -n "/cp/credhub_client_id" -t value \
    -v "credhub-admin"
  credhub set -n "/cp/credhub_client_secret" -t password \
    -w "$(bosh interpolate --no-color $creds_path --path /credhub_admin_client_secret)"

  credhub set -n "/cp/concourse_client_id" -t value \
    -v "concourse"
  credhub set -n "/cp/concourse_client_secret" -t password \
    -w "$(bosh interpolate --no-color $creds_path --path /concourse_client_secret)"
fi

bosh -n update-cloud-config \
  $cloud_config \
  -l ${root_dir}/vars.yml