#!/bin/bash

set -eux

function set_pipeline_defaults() {

  local name=$1
  local product=$2

  #
  # Pipeline specific variables
  #

  credhub set -n "/concourse/main/deploy-${name}-${product}/foundation_name" \
    -t value -v "$name"

  credhub set -n "/concourse/main/deploy-${name}-${product}/default_ca" \
    -t certificate -r "$default_ca"

  credhub set -n "/concourse/main/deploy-${name}-${product}/config_git_repo_url" -t value \
    -v "$automation_git_repo_path"
  credhub set -n "/concourse/main/deploy-${name}-${product}/config_git_repo_key" -t ssh \
    -p "$automation_git_private_key"

  credhub set -n "/concourse/main/deploy-${name}-${product}/s3_url" \
    -t value -v "http://${s3_host}:9000"
  credhub set -n "/concourse/main/deploy-${name}-${product}/s3_accesskey" \
    -t password -w "$s3_accesskey"
  credhub set -n "/concourse/main/deploy-${name}-${product}/s3_secretkey" \
    -t password -w "$s3_secretkey"

  credhub set -n "/concourse/main/deploy-${name}-${product}/credhub_url" \
    -t value -v "$credhub_url"
  credhub set -n "/concourse/main/deploy-${name}-${product}/credhub_client_id" \
    -t value -v "$credhub_client_id"
  credhub set -n "/concourse/main/deploy-${name}-${product}/credhub_client_secret" \
    -t value -v "$credhub_client_secret"
}

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

    #
    # Common deployment automation credentials 
    # interpolated by pcf automation tasks.
    #

    credhub set -n "/pcf/${name}/default_ca" \
      -t certificate -r "$default_ca"
      
    source ${root_dir}/src/scripts/set-foundation-${iaas}-creds.sh

    opsman_host=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_host)
    opsman_user=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_user)
    opsman_password=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_password)
    opsman_decryption_phrase=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_decryption_phrase)
    opsman_ssh_password=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/opsman_ssh_password)

    credhub set -n "/pcf/${name}/opsman_host" \
      -t value -v "$opsman_host"
    credhub set -n "/pcf/${name}/opsman_user" \
      -t value -v "$opsman_user"

    set_credhub_password \
      "/pcf/${name}/opsman_password" "$opsman_password" no
    set_credhub_password \
      "/pcf/${name}/opsman_decryption_phrase" "$opsman_decryption_phrase" no
    set_credhub_password \
      "/pcf/${name}/opsman_ssh_password" "$opsman_ssh_password" no

    set_pipeline_defaults "${name}" "opsman"

    #
    # Set opsman creds for each product pipeline
    #

    num_products=$(bosh interpolate ${root_dir}/vars.yml \
      --path /foundations/$i \
      | grep -e "^-" | wc -l)

    for j in $(seq 0 $((num_products-1))); do
      product=$(bosh interpolate ${root_dir}/vars.yml \
        --path /foundations/$i/products/$j/name)

      set_pipeline_defaults "${name}" "${product}"
      
      num_creds=$(bosh interpolate ${root_dir}/vars.yml \
        --path /foundations/$i/products/$j/creds \
        | grep -e "^-" | wc -l)

      for k in $(seq 0 $((num_creds-1))); do

        cred_name=$(bosh interpolate ${root_dir}/vars.yml \
          --path /foundations/$i/products/$j/creds/$k/name)
        cred_type=$(bosh interpolate ${root_dir}/vars.yml \
          --path /foundations/$i/products/$j/creds/$k/type)
        cred_scope=$(bosh interpolate ${root_dir}/vars.yml \
          --path /foundations/$i/products/$j/creds/$k/scope?)
        regenerate=$(bosh interpolate ${root_dir}/vars.yml \
          --path /foundations/$i/products/$j/creds/$k/regenerate?)
        overwrite=$(bosh interpolate ${root_dir}/vars.yml \
          --path /foundations/$i/products/$j/creds/$k/overwrite?)

        if [[ $cred_scope == pipeline ]]; then
          cred_path_prefix="/concourse/main/deploy-${name}-${product}"
        else
          cred_path_prefix="/pcf/${name}"
        fi

        case $cred_type in
          value)
            cred_value=$(bosh interpolate ${root_dir}/vars.yml \
              --path /foundations/$i/products/$j/creds/$k/value)
            set_credhub_value \
              "${cred_path_prefix}/$cred_name" \
              "$cred_value" \
              "$overwrite"
            ;;

          password)
            cred_value=$(bosh interpolate ${root_dir}/vars.yml \
              --path /foundations/$i/products/$j/creds/$k/value)
            set_credhub_password \
              "${cred_path_prefix}/$cred_name" \
              "$cred_value" \
              "$regenerate"
            ;;

          certificate)
            common_name=$(bosh interpolate ${root_dir}/vars.yml \
              --path /foundations/$i/products/$j/creds/$k/common_name)
            alternate_names=$(bosh interpolate ${root_dir}/vars.yml \
              --path /foundations/$i/products/$j/creds/$k/alternate_names)
            organization=$(bosh interpolate ${root_dir}/vars.yml \
              --path /foundations/$i/products/$j/creds/$k/organization)
            generate_credhub_certificate \
              "${cred_path_prefix}/$cred_name" \
              "$regenerate" \
              "/cp/default_ca" \
              "$common_name" \
              "$alternate_names" \
              "$organization"
            ;;
        esac
      done
    done
  done
fi
