#!/bin/bash

set -eux

default_foundation=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/0/name)

cat << ---EOF > ${root_dir}/.envrc
export root_dir=$root_dir
export iaas=$iaas

$iaas_env

export BOSH_ENVIRONMENT='$(bosh interpolate ${root_dir}/vars.yml --path /dns_name)'
export BOSH_CA_CERT='$(bosh interpolate --no-color $creds_path --path /default_ca/ca)'
export BOSH_CLIENT='admin'
export BOSH_CLIENT_SECRET='$(bosh interpolate --no-color $creds_path --path /admin_password)'

export CREDHUB_SERVER=https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8844
export CREDHUB_CA_CERT=\$BOSH_CA_CERT
export CREDHUB_CLIENT=credhub-admin
export CREDHUB_SECRET='$(bosh interpolate --no-color $creds_path --path /credhub_admin_client_secret)'

export UAA_TARGET=https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8443
export UAA_ADMIN_CLIENT=\$BOSH_CLIENT
export UAA_ADMIN_CLIENT_SECRET=\$BOSH_CLIENT_SECRET

export OM_TARGET="$(credhub get -q -n /pcf/${default_foundation}/opsman_host)"
export OM_USERNAME="$(credhub get -q -n /pcf/${default_foundation}/opsman_user)"
export OM_PASSWORD="$(credhub get -q -n /pcf/${default_foundation}/opsman_password)"
export OM_DECRYPTION_PASSPHRASE="$(credhub get -q -n /pcf/${default_foundation}/opsman_decryption_phrase)"
export OM_SKIP_SSL_VALIDATION=true
---EOF

set +e
which direnv 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
  set -e
  direnv allow
else
  echo "INFO: Unable to find 'direnv' CLI in system path. The '.envrc' has been created but will not be sourced."
fi
source ${root_dir}/.envrc
