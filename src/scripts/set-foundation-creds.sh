#!/bin/bash

set -eux

if [[ $set_foundation_creds == yes ]]; then

  default_ca=$(bosh interpolate --no-color $creds_path --path /default_ca/ca)

  s3_host=$(bosh interpolate ${root_dir}/vars.yml --path /minio_host)
  s3_accesskey=$(credhub get -n /cp/s3_accesskey -q)
  s3_secretkey=$(credhub get -n /cp/s3_secretkey -q)

  credhub_url=$(credhub get -n /cp/credhub_url -q)
  credhub_client_id=$(credhub get -n /cp/credhub_client_id -q)
  credhub_client_secret=$(credhub get -n /cp/credhub_client_secret -q)

  for i in $(seq 0 $((num_foundations-1))); do
    name=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/name)

    credhub set -n "/concourse/main/deploy-${name}/foundation_name" \
      -t value -v "$name"

    credhub set -n "/concourse/main/deploy-${name}/default_ca" \
      -t certificate -c "$default_ca"

    credhub set -n "/concourse/main/deploy-${name}/config_git_repo_url" -t value \
      -v "$automation_git_repo_path"
    credhub set -n "/concourse/main/deploy-${name}/config_git_repo_key" -t ssh \
      -p "$automation_git_private_key"

    credhub set -n "/concourse/main/deploy-${name}/s3_url" 
      -t value -v "http://${s3_host}:9000"
    credhub set -n "/concourse/main/deploy-${name}/s3_accesskey" \
      -t password -w "$s3_accesskey"
    credhub set -n "/concourse/main/deploy-${name}/s3_secretkey"\
      -t password -w "$s3_secretkey"

    credhub set -n "/concourse/main/deploy-${name}/credhub_url" 
      -t value -v "$credhub_url"
    credhub set -n "/concourse/main/deploy-${name}/credhub_client_id" 
      -t value -v "$credhub_client_id"
    credhub set -n "/concourse/main/deploy-${name}/credhub_client_secret" 
      -t value -v "$credhub_client_secret"

    opsman_host=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_host)
    opsman_user=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_user)
    opsman_password=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_password)
    opsman_decryption_phrase=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_decryption_phrase)
    opsman_ssh_password=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_ssh_password)

    credhub set -n "/concourse/main/deploy-${name}/opsman_host" 
      -t value -v "$opsman_host"
    credhub set -n "/concourse/main/deploy-${name}/opsman_user" 
      -t value -v "$opsman_user"

    if [[ "$opsman_password" == "*" ]]; then
      credhub generate -n "/concourse/main/deploy-${name}/opsman_password" -t password
    else
      credhub set -n "/concourse/main/deploy-${name}/opsman_password" 
        -t password -w "$opsman_password"
    fi
    if [[ "$opsman_decryption_phrase" == "*" ]]; then
      credhub generate -n "/concourse/main/deploy-${name}/opsman_decryption_phrase" -t password
    else
      credhub set -n "/concourse/main/deploy-${name}/opsman_decryption_phrase" 
        -t password -w "$opsman_decryption_phrase"
    fi
    if [[ "$opsman_ssh_password" == "*" ]]; then
      credhub generate -n "/concourse/main/deploy-${name}/opsman_ssh_password" -t password
    else
      credhub set -n "/concourse/main/deploy-${name}/opsman_ssh_password" 
        -t password -w "$opsman_ssh_password"
    fi

    source ${root_dir}/src/scripts/set-foundation-${iaas}-creds.sh
  done
fi
