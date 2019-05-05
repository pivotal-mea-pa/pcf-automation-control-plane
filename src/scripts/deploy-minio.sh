#!/bin/bash -eu

apply_local_download_ops_rules=""
if [[ -n $downloads_dir && $downloads_dir != null ]]; then
  apply_local_download_ops_rules="-o ${{ops_file_path}}/minio/op-local-releases.yml"
fi

bosh interpolate \
  ${manifests_file_path}/minio.yml \
  $apply_local_download_ops_rules \
  -l ${root_dir}/vars.yml > $minio_manifest

minio_name=$(bosh interpolate ${root_dir}/vars.yml --path /minio_name)

set +e
bosh -n deployments | grep "$minio_name" 2>&1 >/dev/null
if [[ $action != create-manifests-only \
  && ($action == deploy || $? -ne 0) ]]; then

  set -e
  bosh -n -d $minio_name deploy $minio_manifest
else
  set -e
fi
