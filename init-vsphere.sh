#!/bin/sh

set -e

ROOT_DIR=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')") && pwd)

if [[ ! -e $ROOT_DIR/vars.yml ]]; then
  echo "Unable to find the control plane external variable file 'vars.yml'."
  exit 1
fi

BOSH_DEPLOYMENT_HOME=$ROOT_DIR/vendor/bosh-deployment
OPS_FILE_PATH=$ROOT_DIR/ops-files

mkdir -p $ROOT_DIR/.state
STATE_PATH=$ROOT_DIR/.state/control-plan-state.json 
CREDS_PATH=$ROOT_DIR/.state/control-plan-creds.yml
BOSH_MANIFEST=$ROOT_DIR/.state/control-plan-manifest.yml
KEYS_PATH=$ROOT_DIR/keys

if [[ $1 == "update" \
  || ! -e $STATE_PATH \
  || ! -e $CREDS_PATH ]]; then

bosh create-env \
  $BOSH_DEPLOYMENT_HOME/bosh.yml \
  -o $BOSH_DEPLOYMENT_HOME/uaa.yml \
  -o $BOSH_DEPLOYMENT_HOME/credhub.yml \
  -o $BOSH_DEPLOYMENT_HOME/vsphere/cpi.yml \
  -o $OPS_FILE_PATH/bosh/op-network.yml \
  -o $OPS_FILE_PATH/bosh/op-bosh-vm.yml \
  -o $OPS_FILE_PATH/bosh/op-uaa.yml \
  -o $OPS_FILE_PATH/bosh/op-credhub.yml \
  -o $OPS_FILE_PATH/bosh/op-uaa-url.yml \
  --vars-store=$CREDS_PATH \
  --vars-file=$ROOT_DIR/vars.yml \
  --var-file=private_key=$KEYS_PATH/pcf.pem \
  --state=$STATE_PATH
fi

bosh interpolate \
  $BOSH_DEPLOYMENT_HOME/bosh.yml \
  -o $BOSH_DEPLOYMENT_HOME/uaa.yml \
  -o $BOSH_DEPLOYMENT_HOME/credhub.yml \
  -o $BOSH_DEPLOYMENT_HOME/vsphere/cpi.yml \
  -o $OPS_FILE_PATH/bosh/op-network.yml \
  -o $OPS_FILE_PATH/bosh/op-bosh-vm.yml \
  -o $OPS_FILE_PATH/bosh/op-uaa.yml \
  -o $OPS_FILE_PATH/bosh/op-credhub.yml \
  -o $OPS_FILE_PATH/bosh/op-uaa-url.yml \
  --vars-file=$ROOT_DIR/vars.yml \
  --var-file=private_key=$KEYS_PATH/pcf.pem > $BOSH_MANIFEST

set +e
which direnv 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
  set -e

  cat << ---EOF > $ROOT_DIR/.envrc
source_up .envrc

export BOSH_ENVIRONMENT='$(bosh interpolate $ROOT_DIR/vars.yml --path /dns_name)'
export BOSH_CA_CERT='$(bosh interpolate --no-color $CREDS_PATH --path /director_ssl/ca)'
export BOSH_CLIENT='admin'
export BOSH_CLIENT_SECRET='$(bosh interpolate --no-color $CREDS_PATH --path /admin_password)'

export CREDHUB_SERVER=https://$(bosh interpolate $ROOT_DIR/vars.yml --path /dns_name):8844
export CREDHUB_CA_CERT='$(bosh interpolate --no-color $CREDS_PATH --path /credhub_tls/ca)'
export CREDHUB_CLIENT=credhub-admin
export CREDHUB_SECRET='$(bosh interpolate --no-color $CREDS_PATH --path /credhub_admin_client_secret)'

export UAA_TARGET=https://$(bosh interpolate $ROOT_DIR/vars.yml --path /dns_name)T:8443
export UAA_ADMIN_CLIENT=\$BOSH_CLIENT
export UAA_ADMIN_CLIENT_SECRET=\$BOSH_CLIENT_SECRET
---EOF

  direnv allow
fi
