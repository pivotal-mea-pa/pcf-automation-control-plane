#!/bin/bash

action=$1

which packer 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR! The packer CLI is not present in the system path."
  exit 1
fi

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

source ${root_dir}/src/scripts/stemcell-build/stemcell-build.sh
