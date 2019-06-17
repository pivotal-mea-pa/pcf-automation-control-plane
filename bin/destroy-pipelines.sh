#!/bin/bash

set +e
concourse_status=$(fly -t cp status 2>&1)

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

concourse_external_host=$(bosh interpolate ${root_dir}/vars.yml --path /concourse_external_host)
[[ "$concourse_status" == "logged in successfully" ]] || \
  fly -t cp login -k -c https://$concourse_external_host

num_foundations=$(bosh interpolate ${root_dir}/vars.yml --path /foundations | grep -e "^-" | wc -l)
for i in $(seq 0 $((num_foundations-1))); do
  name=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/name)

  fly -t cp destroy-pipeline -n \
    -p deploy-${name}-opsman

  num_products=$(bosh interpolate ${root_dir}/vars.yml \
    --path /foundations/$i \
    | grep -e "^-" | wc -l)

  for j in $(seq 0 $((num_products-1))); do
    product=$(bosh interpolate ${root_dir}/vars.yml \
      --path /foundations/$i/products/$j/name)

  fly -t cp destroy-pipeline  -n \
    -p deploy-${name}-${product}

  done
done
