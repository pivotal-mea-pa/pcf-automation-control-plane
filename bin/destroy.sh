#!/bin/bash

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

echo -e "\n!!! WARNING DELETING ALL DEPLOYMENTS !!!\n"

for d in $(bosh deployments | awk '/bosh-/{ print $1 }'); do 
  bosh -d $d delete-deployment --force
done

key_file=""
if [[ -e ${root_dir}/keys/pcf.pem ]]; then
  key_file="--var-file=private_key=${root_dir}/keys/pcf.pem"
fi

bosh delete-env \
  $key_file \
  --state .state/cp-state.json \
  --vars-store .state/cp-creds.yml \
  .state/cp-manifest.yml
