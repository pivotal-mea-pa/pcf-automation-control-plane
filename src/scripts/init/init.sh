#!/bin/bash

source ${root_dir}/src/scripts/init/funcs.sh

set -eux

#
# Load and setup environment for control 
# plane initialization scripts
#

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
pcf_config_repo_path=${root_dir}/.repos/config
pcf_state_repo_path=${root_dir}/.repos/state

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

if [[ ! -e $creds_path && $action == create-manifests-only ]]; then
  echo "Credential store file is missing. You may need to deploy the environment first."
  exit 1
fi

set +e
which shasum 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "Unable to locate shasum cli."
  exit 1
fi
set -e

num_foundations=$(bosh interpolate ${root_dir}/vars.yml --path /foundations | grep -e "^-" | wc -l)

#
# Determine if automation configuration and 
# state repositories will be hosted locally
#

init_automation=$(bosh interpolate ${root_dir}/vars.yml --path /init_automation)
automation_config_repo_path=$(bosh interpolate ${root_dir}/vars.yml --path /automation_config_repo_path)
automation_state_repo_path=$(bosh interpolate ${root_dir}/vars.yml --path /automation_state_repo_path)
automation_git_private_key=$(bosh interpolate ${root_dir}/vars.yml --path /automation_git_private_key)

if [[ $init_automation == true ]]; then

  if [[ -z $automation_config_repo_path || $automation_config_repo_path == null ]]; then

    local_itf=$(ip a | awk '/^[0-9]+: (eth|ens?)[0-9]+:/{ print substr($2,1,length($2)-1) }' | head -1)
    local_ip=$(ifconfig $local_itf | awk '/inet addr:/{ print substr($2,6) }')

    if [[ -z $local_ip ]]; then
      echo "Unable to determine the this host's IP for setting up git remote environment on this host."
      exit 1
    fi

    [[ -e $HOME/.ssh/git.pem ]] || \
      ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/git.pem

    set +e
    grep "Host $local_ip" $HOME/.ssh/config >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then

      touch $HOME/.ssh/config
    cat << ---EOF >> $HOME/.ssh/config

Host $local_ip
  AddKeysToAgent yes
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  IdentityFile $HOME/.ssh/git.pem
---EOF

    fi
    set -e
    
    automation_config_repo_path=git@${local_ip}:pcf-configuration.git
    automation_state_repo_path=git@${local_ip}:pcf-state.git
    automation_git_private_key=$(cat $HOME/.ssh/git.pem)
    local_git_server=yes
  else
    local_git_server=no
  fi
fi

#
# Checksums to not repeat certain tasks if 
# there is no change to configuration
#

ubuntu_stemcell_sha1=""
creds_sha1=""

checksums_path=${root_dir}/.state/checksums
touch $checksums_path
source $checksums_path

#
# Run control plan initialization scripts
#

source ${root_dir}/src/scripts/init/deploy-bosh.sh
source ${root_dir}/src/scripts/init/deploy-concourse.sh
source ${root_dir}/src/scripts/init/deploy-minio.sh

[[ update_credentials == no ]] || \
  source ${root_dir}/src/scripts/init/set-credhub-vars/set-foundation-creds.sh

[[ $init_automation != true ]] || \
  source ${root_dir}/src/scripts/init/setup-automation/init-automation-repo.sh
