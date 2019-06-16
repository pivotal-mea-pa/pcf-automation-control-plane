#!/bin/bash

set -eux

stemcell_image_id=$(openstack --insecure image list \
  | awk "/ ${image_build_name} /{ print \$2 }")

glance --insecure image-download --progress \
  --file ${stemcell_disk_image} "${stemcell_image_id}" 2>/dev/null
