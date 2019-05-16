#!/bin/bash

set -eux

apply_local_download_ops_rules=""
if [[ -n $downloads_dir && $downloads_dir != null ]]; then
  apply_local_download_ops_rules="-o ${ops_file_path}/minio/op-local-releases.yml"
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

  s3_host=$(bosh interpolate ${root_dir}/vars.yml --path /minio_host)
  s3_accesskey=$(credhub get -q -n '/cp/s3_accesskey')
  s3_secretkey=$(credhub get -q -n '/cp/s3_secretkey')

  mc config host add auto http://$s3_host:9000 $s3_accesskey $s3_secretkey

  [[ $(mc ls auto/ | awk '/pivnet-products\/$/{ print $5 }') == pivnet-products/ ]] || \
    mc mb auto/pivnet-products
  [[ $(mc ls auto/ | awk '/pcf-exports\/$/{ print $5 }') == pcf-exports/ ]] || \
    mc mb auto/pcf-exports
fi
