#!/bin/bash

set -eux

updated_creds_sha1=$(echo -e \
  "$(cat ${root_dir}/vars.yml $creds_path $HOME/.ssh/git.pem) $automation_git_repo_path" \
  | shasum | cut -d' ' -f1)

set +e
which credhub 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
  set -e

  if [[ "$updated_creds_sha1" != "$creds_sha1" ]]; then

    credhub login

    credhub set -n "/cp/default_ca" -t certificate \
      -r "$(bosh interpolate --no-color $creds_path --path /default_ca/ca)" \
      -c "$(bosh interpolate --no-color $creds_path --path /default_ca/certificate)" \
      -p "$(bosh interpolate --no-color $creds_path --path /default_ca/private_key)"

    credhub set -n "/cp/bosh_host" -t value \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /dns_name)"    
    credhub set -n "/cp/uaa_url" -t value \
      -v "https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8443"

    credhub set -n "/cp/admin_client" -t value \
      -v "admin"
    credhub set -n "/cp/admin_client_secret" -t value \
      -v "$(bosh interpolate --no-color $creds_path --path /admin_password)"

    credhub set -n "/cp/credhub_url" -t value \
      -v "https://$(bosh interpolate ${root_dir}/vars.yml --path /dns_name):8844"
    credhub set -n "/cp/credhub_client_id" -t value \
      -v "credhub-admin"
    credhub set -n "/cp/credhub_client_secret" -t password \
      -w "$(bosh interpolate --no-color $creds_path --path /credhub_admin_client_secret)"

    credhub set -n "/cp/s3_url" -t value \
      -v "http://$(bosh interpolate ${root_dir}/vars.yml --path /minio_host):9000"

    credhub set -n "/cp/concourse_client_id" -t value \
      -v "concourse"
    credhub set -n "/cp/concourse_client_secret" -t password \
      -w "$(bosh interpolate --no-color $creds_path --path /concourse_client_secret)"

    credhub set -n "/pcf/config_git_repo_url" -t value \
      -v "$automation_git_repo_path"
    credhub set -n "/pcf/config_git_repo_key" -t ssh \
      -p "$HOME/.ssh/git.pem" \
      -u "$HOME/.ssh/git.pem.pub"

    # Foundation specific variables

    credhub set -n "/pcf-sandbox/vcenter-ip" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /vcenter_ip)"
    credhub set -n "/pcf-sandbox/vcenter-user" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /vcenter_user)"
    credhub set -n "/pcf-sandbox/vcenter-password" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /vcenter_password)"

    credhub set -n "/pcf-sandbox/opsman-host" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /opsman_sandbox_host)"
    credhub set -n "/pcf-sandbox/opsman-user" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /opsman_sandbox_user)"
    credhub set -n "/pcf-sandbox/opsman-password" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /opsman_sandbox_password)"
    credhub set -n "/pcf-sandbox/opsman-decryption_phrase" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /opsman_sandbox_decryption_phrase)"
    credhub set -n "/pcf-sandbox/opsman-ssh-password" \
      -v "$(bosh interpolate ${root_dir}/vars.yml --path /opsman_sandbox_ssh_password)"
    credhub set -n "/pcf-sandbox/pas-credhub-encryption_key" -t password \
      -w "$(bosh interpolate ${root_dir}/vars.yml --path /pas_credhub_encryption_key)"

    (grep "^creds_sha1=" .state/checksums 2>&1 >/dev/null \
        && sed -i "s|^creds_sha1=.*|creds_sha1=${updated_creds_sha1}|" .state/checksums) \
    || echo -e "creds_sha1=${updated_creds_sha1}" >> .state/checksums
  fi
else
  echo "INFO: Unable to find 'credhub' CLI in system path. Credhub will not be updated."
fi
