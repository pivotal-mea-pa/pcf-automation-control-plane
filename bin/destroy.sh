#!/bin/bash

set -e

echo -e "\n!!! WARNING DELETING ALL DEPLOYMENTS !!!\n"

for d in $(bosh deployments | awk '/bosh-/{ print $1 }'); do 
  bosh -d $d delete-deployment --force
done

key_file=""
if [[ -e ${keys_path}/pcf.pem ]]; then
  key_file="--var-file=private_key=${keys_path}/pcf.pem"
fi

bosh delete-env \
  $key_file \
  --state .state/cp-state.json \
  --vars-store .state/cp-creds.yml \
  .state/cp-manifest.yml
