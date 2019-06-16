#!/bin/bash

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

pivnet_download_dir=${root_dir}/.downloads/pivnet

#
# Download platform automation release
#

mkdir -p $pivnet_download_dir/automation

platform_automation_slug="platform-automation"
platform_automation_version='3\..*\..*'
release=$(pivnet releases -p "${platform_automation_slug}" \
  | awk "/^\\|\\s+[0-9]+ \\| ${platform_automation_version}/{ print \$4 }" \
  | head -1)

product_file_name=$(basename $(pivnet product-files -p "${platform_automation_slug}" -r "${release}" \
  | awk -F'|' '/Concourse Tasks/{ print $7 }' \
  | sed 's|\s||g'))
if [[ ! -e $pivnet_download_dir/automation/$product_file_name ]]; then
  echo "Downloading Concourse Tasks ... "

  concourse_task_archive_id=$(pivnet product-files -p "${platform_automation_slug}" -r "${release}" \
    | awk '/Concourse Tasks/{ print $2 }')
  pivnet download-product-files --accept-eula \
    -p "${platform_automation_slug}" \
    -r "${release}" \
    -i "${concourse_task_archive_id}" \
    -d $pivnet_download_dir/automation
fi

product_file_name=$(basename $(pivnet product-files -p "${platform_automation_slug}" -r "${release}" \
  | awk -F'|' '/Docker Image for Concourse/{ print $7 }' \
  | sed 's|\s||g'))
if [[ ! -e $pivnet_download_dir/automation/$product_file_name ]]; then
  echo "Downloading Docker Image for Concourse ... "

  docker_image_archive_id=$(pivnet product-files -p "${platform_automation_slug}" -r "${release}" \
    | awk '/Docker Image for Concourse/{ print $2 }')
  pivnet download-product-files --accept-eula \
    -p "${platform_automation_slug}" \
    -r "${release}" \
    -i "${docker_image_archive_id}" \
    -d $pivnet_download_dir/automation
fi

#
# Download Pivotal product releases
#

num_products=$(bosh interpolate ${root_dir}/vars.yml \
  --path /pivnet_products \
  | grep -e "^-" | wc -l)

for i in $(seq 0 $((num_products-1))); do

  name=$(bosh interpolate ${root_dir}/vars.yml \
    --path /pivnet_products/$i/name)
  pivnet_slug=$(bosh interpolate ${root_dir}/vars.yml \
    --path /pivnet_products/$i/pivnet_slug)
  pivnet_version=$(bosh interpolate ${root_dir}/vars.yml \
    --path /pivnet_products/$i/pivnet_version)
  product_file_pattern=$(bosh interpolate ${root_dir}/vars.yml \
    --path /pivnet_products/$i/product_file_pattern)
  stemcell_file_pattern=$(bosh interpolate ${root_dir}/vars.yml \
    --path /pivnet_products/$i/stemcell_file_pattern?)

  mkdir -p $pivnet_download_dir/$name  

  release=$(pivnet releases -p "${pivnet_slug}" \
    | awk "/^\\|\\s+[0-9]+ \\| ${pivnet_version}/{ print \$4 }" \
    | head -1)
  product_file_id=$(pivnet product-files -p "${pivnet_slug}" -r "${release}" \
    | awk "/\/${product_file_pattern}/{ print \$2 }")
  product_file_name=$(basename $(pivnet product-files -p "${pivnet_slug}" -r "${release}" \
    | awk -F'|' "/\/${product_file_pattern}/{ print \$7 }" \
    | sed 's|\s||g'))

  if [[ ! -e $pivnet_download_dir/$name/$product_file_name ]]; then
    echo "Downloading product $name ... "
    pivnet download-product-files --accept-eula \
      -p "${pivnet_slug}" \
      -r "${release}" \
      -i "${product_file_id}" \
      -d $pivnet_download_dir/$name
  else
    echo "Product $name release $release already downloaded ... "
  fi

  if [[ $stemcell_file_pattern != null ]]; then
    stemcell_version=$(pivnet release-dependencies -p "${pivnet_slug}" -r "${release}" \
      | awk '$6=="233" { print $4 }' \
      | head -1)

    if [[ -n $stemcell_version ]]; then
      stemcell_file_id=$(pivnet product-files -p stemcells-ubuntu-xenial -r "${stemcell_version}" \
        | awk "/\/${stemcell_file_pattern}/{ print \$2 }")
      stemcell_file_name=$(basename $(pivnet product-files -p stemcells-ubuntu-xenial -r "${stemcell_version}" \
        | awk -F'|' "/\/${stemcell_file_pattern}/{ print \$7 }" \
        | sed 's|\s||g'))

      if [[ ! -e $pivnet_download_dir/$name/$stemcell_file_name ]]; then
        echo "Downloading stemcell for product $name ... "
        pivnet download-product-files --accept-eula \
          -p "stemcells-ubuntu-xenial" \
          -r "${stemcell_version}" \
          -i "${stemcell_file_id}" \
          -d $pivnet_download_dir/$name
      else
        echo "Stemcell for product $name release $release already downloaded ... "
      fi
    fi
  fi
done
