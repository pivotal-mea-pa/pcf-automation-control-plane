#!/bin/bash

set -eu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

pivnet_download_dir=${root_dir}/.downloads/pivnet

# Login to minio
s3_host=$(bosh interpolate ${root_dir}/vars.yml --path /minio_host)
s3_accesskey=$(credhub get -n /cp/s3_accesskey -q)
s3_secretkey=$(credhub get -n /cp/s3_secretkey -q)

mc config host add auto http://${s3_host}:9000 $s3_accesskey $s3_secretkey
mc mirror $pivnet_download_dir auto/pivnet-products/
