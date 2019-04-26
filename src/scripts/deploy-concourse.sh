#!/bin/bash

bosh interpolate \
  ${concourse_deployment_home}/cluster/concourse.yml \
  -o ${ops_file_path}/concourse/op-concourse.yml \
  -o ${ops_file_path}/concourse/op-network.yml \
  -o ${ops_file_path}/concourse/op-credhub.yml \
  -l ${concourse_deployment_home}/versions.yml \
  -l ${root_dir}/vars.yml > $concourse_manifest

    # --vars-store cluster-creds.yml \
    # -o operations/static-web.yml \
    # -o operations/basic-auth.yml \
    # --var local_user.username=admin \
    # --var local_user.password=admin \

    # --var web_vm_type=concourse \
    # --var db_vm_type=concourse \
    # --var db_persistent_disk_type=db \
    # --var worker_vm_type=concourse \
    # --var deployment_name=concourse
