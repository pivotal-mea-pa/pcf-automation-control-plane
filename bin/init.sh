#!/bin/bash

iaas=$1
action=${2:-create-manifests-only}

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

source ${root_dir}/src/scripts/init/init.sh