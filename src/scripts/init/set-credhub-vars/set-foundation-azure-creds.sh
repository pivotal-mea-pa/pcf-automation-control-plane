#!/bin/bash

set -eux

azure_subscription_id=$(bosh interpolate ${root_dir}/vars.yml --path /subscription_id)
azure_tenant_id=$(bosh interpolate ${root_dir}/vars.yml --path /tenant_id)
azure_resource_group=$(bosh interpolate ${root_dir}/vars.yml --path /resource_group_name)
azure_client_id=$(bosh interpolate ${root_dir}/vars.yml --path /client_id)
azure_client_secret=$(bosh interpolate ${root_dir}/vars.yml --path /client_secret)
azure_location=$(bosh interpolate ${root_dir}/vars.yml --path /location)
azure_network_security_group=$(bosh interpolate ${root_dir}/vars.yml --path /default_security_group)
azure_network_vpc_subnet=$(bosh interpolate ${root_dir}/vars.yml --path /vpc_subnet)
azure_network_storage_account=$(bosh interpolate ${root_dir}/vars.yml --path /storage_account_name)
azure_network_ssh_public_key=$(bosh interpolate ${root_dir}/vars.yml --path /ssh.public_key)
azure_network_ssh_private_key=$(bosh interpolate ${root_dir}/vars.yml --path /ssh.private_key)
# PCF automation interpolated
credhub set -n "/pcf/${name}/azure_subscription_id" \
  -t value -v "$azure_subscription_id"
credhub set -n "/pcf/${name}/azure_tenant_id" \
  -t value -v "$azure_tenant_id"
credhub set -n "/pcf/${name}/azure_resource_group" \
  -t password -w "$azure_resource_group"
credhub set -n "/pcf/${name}/azure_client_id" \
  -t value -v "$azure_client_id"
credhub set -n "/pcf/${name}/azure_client_secret" \
  -t value -v "$azure_client_secret"
credhub set -n "/pcf/${name}/azure_location" \
  -t value -v "$azure_location"
credhub set -n "/pcf/${name}/azure_network_security_group" \
  -t value -v "$azure_network_security_group"
credhub set -n "/pcf/${name}/azure_network_vpc_subnet" \
  -t value -v "$azure_network_vpc_subnet"
credhub set -n "/pcf/${name}/azure_network_storage_account" \
  -t value -v "$azure_network_storage_account"
credhub set -n "/pcf/${name}/azure_network_ssh" \
  -t ssh -u "$azure_network_ssh_public_key"
credhub set -n "/pcf/${name}/azure_network_ssh" \
 -t ssh -p "$azure_network_ssh_private_key"