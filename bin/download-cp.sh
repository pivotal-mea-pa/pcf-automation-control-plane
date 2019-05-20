#!/bin/bash

iaas=${1:vsphere}

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

downloads_dir=${root_dir}/.downloads/cp

mkdir -p $downloads_dir
pushd $downloads_dir

stemcell=$(bosh interpolate ${root_dir}/vars.yml --path /ubuntu_stemcell)
curl -JLO $stemcell
fi

downloads=$(find ${root_dir}/src -name "op-local-releases.yml" -exec cat {} \; | awk '/# https?:\/\//{ print $2 }')
for u in $downloads; do 
  curl -JLO $u
done
downloads=$(find ${root_dir}/src -name "op-local-${iaas}-releases.yml" -exec cat {} \; | awk '/# https?:\/\//{ print $2 }')
for u in $downloads; do 
  curl -JLO $u
done

popd
