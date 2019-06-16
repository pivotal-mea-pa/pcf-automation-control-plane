#!/bin/bash

set -eux

apply_local_download_ops_rules=""
if [[ -n $downloads_dir && $downloads_dir != null ]]; then
  apply_local_download_ops_rules="-o ${ops_file_path}/concourse/op-local-releases.yml"
fi

iaas_ops_rules=""
if [[ -e ${ops_file_path}/minio/op-${iaas}.yml ]]; then
  iaas_ops_rules="-o ${ops_file_path}/minio/op-${iaas}.yml"
fi

bosh interpolate \
  ${concourse_deployment_home}/cluster/concourse.yml \
  $apply_local_download_ops_rules \
  $iaas_ops_rules \
  -o ${ops_file_path}/concourse/op-concourse.yml \
  -o ${ops_file_path}/concourse/op-network.yml \
  -o ${ops_file_path}/concourse/op-credhub.yml \
  -o ${ops_file_path}/concourse/op-oauth.yml \
  -l ${concourse_deployment_home}/versions.yml \
  -l ${root_dir}/vars.yml > $concourse_manifest

concourse_name=$(bosh interpolate ${root_dir}/vars.yml --path /concourse_name)

set +e
bosh -n deployments | grep "$concourse_name" 2>&1 >/dev/null
if [[ $action != create-manifests-only \
  && ($action == deploy || $? -ne 0) ]]; then

  set -e
  bosh -n -d $concourse_name deploy $concourse_manifest
fi
