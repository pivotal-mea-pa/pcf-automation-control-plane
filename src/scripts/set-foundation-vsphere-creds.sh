#!/bin/bash

set -eux

vcenter_ip=$(bosh interpolate ${root_dir}/vars.yml --path /vcenter_ip)
vcenter_user=$(bosh interpolate ${root_dir}/vars.yml --path /vcenter_user)
vcenter_password=$(bosh interpolate ${root_dir}/vars.yml --path /vcenter_password)

# PCF automation interpolated
credhub set -n "/pcf/${name}/vcenter_ip" \
  -t value -v "$vcenter_ip"
credhub set -n "/pcf/${name}/vcenter_user" \
  -t value -v "$vcenter_user"
credhub set -n "/pcf/${name}/vcenter_password" \
  -t password -w "$vcenter_password"

credhub set -n "/pcf/${name}/vcenter_vm_folder" \
  -t value -v "pcf-vms-${name}"

# Pipeline specific variables
credhub set -n "/concourse/main/deploy-${name}-opsman/opsman_image_s3_versioned_regexp" \
  -t value -v "pcf-vsphere-(.*).ova"
