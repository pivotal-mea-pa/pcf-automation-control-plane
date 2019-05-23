#!/bin/bash

set -eux

uploaded=$(bosh stemcells | awk "/\t$version\\*?/{ print \$3 }")
if [[ -z $uploaded ]]; then
  bosh upload-stemcell ${stemcell_build_path}/${stemcell_archive_name}
  
  uploaded=$(bosh stemcells | awk "/$version/{ print \$3 }")
  if [[ $uploaded != $operating_system ]]; then
    echo "Stemcell OS name mismatch. The uploaded name is '$uploaded', but the stemcell file name was labeled '$operating_system'."
    exit 1
  fi
fi

pushd ${root_dir}/src/stemcells/tests/windows-test-bosh-release

bosh create-release --force
bosh upload-release
bosh -n -d windows-stemcell-test deploy \
  manifest.yml --var=stemcell_operating_system=$operating_system

popd

rm -f ${root_dir}/.stembuild/windows-stemcell-test-*.tgz
bosh -d windows-stemcell-test logs --dir ${root_dir}/.stembuild/

pushd ${root_dir}/.stembuild/
tar xvzf windows-stemcell-test-*.tgz

cat ./say-hello/say-hello/job-service-wrapper.out.log \
  | grep "I am executing a BOSH job. FOO=BAR" 2>&1 >/dev/null

rm -fr ./say-hello
popd

rm -f ${root_dir}/.stembuild/windows-stemcell-test-*.tgz
bosh -n -d windows-stemcell-test delete-deployment

echo "No errors detected..."
