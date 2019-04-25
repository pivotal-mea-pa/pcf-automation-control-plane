#!/bin/bash

if [[ -z $iaas ]]; then
  echo "IAAS name is not speficied!"
  exit 1
fi

if [[ ! -e $root_dir/vars.yml ]]; then
  echo "Unable to find the control plane external variable file 'vars.yml'."
  exit 1
fi

bosh_deployment_home=${root_dir}/vendor/bosh-deployment
concourse_deployment_home=${root_dir}/vendor/concourse-bosh-deployment
scripts_file_path=${root_dir}/src/scripts
ops_file_path=${root_dir}/src/ops-files
keys_path=${root_dir}/keys

mkdir -p ${root_dir}/.state
state_path=${root_dir}/.state/cp-state.json 
creds_path=${root_dir}/.state/cp-creds.yml
bosh_manifest=${root_dir}/.state/cp-manifest.yml

downloads_dir=$(bosh interpolate --no-color ${root_dir}/vars.yml --path /downloads_dir)

if [[ ! -e ${bosh_deployment_home}/${iaas} ]]; then
  echo "Unknown IAAS name '$iaas'!"
  exit 1
fi
