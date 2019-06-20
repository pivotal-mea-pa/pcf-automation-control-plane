#!/bin/bash

iaas=$1
action=${2:-create-manifests-only}

which bosh 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR! The bosh CLI is not present in the system path."
  exit 1
fi

which credhub 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR! The credhub CLI is not present in the system path."
  exit 1
fi

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

source ${root_dir}/src/scripts/init/init.sh