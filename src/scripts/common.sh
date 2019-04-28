#!/bin/bash

if [[ -z $iaas \
  || ( $action != create-manifests-only \
    && $action != deploy ) ]]; then
  echo "USAGE: init.sh <IAAS> [ create-manifests-only | deploy ]"
  exit 1
fi

if [[ ! -e $root_dir/vars.yml ]]; then
  echo "Unable to find the control plane external variable file 'vars.yml'."
  exit 1
fi

bosh_deployment_home=${root_dir}/vendor/bosh-deployment
concourse_deployment_home=${root_dir}/vendor/concourse-bosh-deployment
scripts_file_path=${root_dir}/src/scripts
manifests_file_path=${root_dir}/src/manifests
ops_file_path=${root_dir}/src/ops-files
keys_path=${root_dir}/keys

mkdir -p ${root_dir}/.state
state_path=${root_dir}/.state/cp-state.json 
creds_path=${root_dir}/.state/cp-creds.yml
bosh_manifest=${root_dir}/.state/cp-manifest.yml
cloud_config=${root_dir}/.state/cp-cloud-config.yml
concourse_manifest=${root_dir}/.state/concourse-manifest.yml
minio_manifest=${root_dir}/.state/minio-manifest.yml

downloads_dir=$(bosh interpolate --no-color ${root_dir}/vars.yml --path /downloads_dir)

if [[ ! -e ${bosh_deployment_home}/${iaas} ]]; then
  echo "Unknown IAAS name '$iaas'!"
  exit 1
fi

set +e
which shasum 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "Unable to locate shasum cli."
  exit 1
fi

checksums_path=${root_dir}/.state/checksums
touch $checksums_path
source $checksums_path

