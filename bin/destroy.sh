#!/bin/bash

set -e

for d in $(bosh deployments | awk '/bosh-/{ print $1 }'); do 
  bosh -d $d delete-deployment --force
done

bosh delete-env \
  --state .state/cp-state.json \
  --vars-store .state/cp-creds.yml \
  .state/cp-manifest.yml
