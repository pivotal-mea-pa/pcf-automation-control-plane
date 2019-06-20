#!/bin/bash

iaas=${1:-vsphere}
echo=${2:-}

which curl 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR! The curl CLI is not present in the system path."
  exit 1
fi

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

downloads_dir=${root_dir}/.downloads/cp

mkdir -p $downloads_dir
pushd $downloads_dir

if [[ $echo == yes ]]; then
  echo -e "\nDownload the following URLs and copy them to the $downloads_dir folder.\n"
fi

stemcell=$(bosh interpolate ${root_dir}/vars.yml --path /ubuntu_stemcell)
if [[ $echo == yes ]]; then
  echo -e "  * $stemcell"
else
  curl -JLO $stemcell
fi

downloads=$(find ${root_dir}/src -name "op-local-releases.yml" -exec cat {} \; | awk '/# https?:\/\//{ print $2 }')
for u in $downloads; do 
  if [[ $echo == yes ]]; then
    echo -e "  * $u"
  else
    curl -JLO $u
  fi
done
downloads=$(find ${root_dir}/src -name "op-local-${iaas}-releases.yml" -exec cat {} \; | awk '/# https?:\/\//{ print $2 }')
for u in $downloads; do 
  if [[ $echo == yes ]]; then
    echo -e "  * $u"
  else
    curl -JLO $u
  fi
done

echo
popd
