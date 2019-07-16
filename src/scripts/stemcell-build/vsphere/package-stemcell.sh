#!/bin/bash

set -eux

if [[ ! -e ${stemcell_build_path}/${stemcell_archive_name} \
  || $action == clean ]]; then
  rm -f ${stemcell_build_path}/${stemcell_archive_name}

  if [[ ! -e $stemcell_disk_image ]]; then
    echo "Unable to find disk file for stemcell. Please do a clean rebuild."
    exit 1
  fi

  mkdir -p ${stemcell_build_path}/tmp
  pushd ${stemcell_build_path}/tmp

  # stembuild package \
  #   -vmdk $stemcell_disk_image
  #   -outputDir ${stemcell_build_path}/tmp

  # Repackage stemcell with correct version
  tar -xzf bosh-stemcell-*.tgz
  sed -i '' "s|version:.*|version: '$version'|" stemcell.MF
  tar -czf ${stemcell_build_path}/${stemcell_archive_name} stemcell.MF image
  
  popd
  rm -fr ${stemcell_build_path}/tmp
fi
