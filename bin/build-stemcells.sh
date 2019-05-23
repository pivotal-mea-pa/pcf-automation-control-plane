#!/bin/bash

action=$1

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

source ${root_dir}/src/scripts/stemcell-build/stemcell-build.sh
