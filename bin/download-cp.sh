#!/bin/bash

which curl 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
  echo "ERROR! The curl CLI is not present in the system path."
  exit 1
fi

iaas=${1:-vsphere}

echo=""
if [[ "$2" == "echo" ]]; then
  echo="echo"
fi

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

downloads_dir=${root_dir}/.downloads/cp

mkdir -p $downloads_dir
pushd $downloads_dir

if [[ -n $echo ]]; then
  echo -e "\nDownload the following URLs and copy them to the $downloads_dir folder.\n"
fi

stemcell=$(bosh interpolate ${root_dir}/vars.yml --path /ubuntu_stemcell)
if [[ -n $echo ]]; then
  echo -e "  * $stemcell"
else
  curl -JLO $stemcell
fi

downloads=$(find ${root_dir}/src -name "op-local-releases.yml" -exec cat {} \; | awk '/# https?:\/\//{ print $2 }')
for u in $downloads; do 
  if [[ -n $echo  ]]; then
    echo -e "  * $u"
  else
    curl -JLO $u
  fi
done
downloads=$(find ${root_dir}/src -name "op-local-${iaas}-releases.yml" -exec cat {} \; | awk '/# https?:\/\//{ print $2 }')
for u in $downloads; do 
  if [[ -n $echo  ]]; then
    echo -e "  * $u"
  else
    curl -JLO $u
  fi
done

echo
popd
