#!/bin/bash

if [[ -n $update \
  || ! -e $state_path \
  || ! -e $creds_path ]]; then

  deploy -d concourse concourse.yml \
    -l ../versions.yml \
    --vars-store cluster-creds.yml \
    -o operations/static-web.yml \
    -o operations/basic-auth.yml \
    --var local_user.username=admin \
    --var local_user.password=admin \
    --var web_ip=10.244.15.2 \
    --var external_url=http://10.244.15.2:8080 \
    --var network_name=concourse \
    --var web_vm_type=concourse \
    --var db_vm_type=concourse \
    --var db_persistent_disk_type=db \
    --var worker_vm_type=concourse \
    --var deployment_name=concourse

fi