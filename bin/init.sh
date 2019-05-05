#!/bin/bash

iaas=$1
action=${2:-create-manifests-only}

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

source ${root_dir}/src/scripts/common.sh
source ${root_dir}/src/scripts/deploy-bosh.sh
source ${root_dir}/src/scripts/deploy-concourse.sh
source ${root_dir}/src/scripts/deploy-minio.sh
set -x
[[ $(bosh interpolate ${root_dir}/vars.yml --path /init_automation_repo) != true ]] || \
  source ${root_dir}/src/scripts/init-automation-repo.sh
