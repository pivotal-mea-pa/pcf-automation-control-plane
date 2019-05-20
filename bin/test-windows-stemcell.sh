#!/bin/bash

os_name=$1
stemcell_version=$2
if [[ -z $os_name || -z $stemcell_version ]]; then
  echo "USAGE: ./test-windows-stemcell.sh [OS_NAME] [STEMCELL_VERSION]"
  exit 1
fi

set -eux
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

os_name=$(bosh stemcells | awk "/\t$stemcell_version\\*?/{ print \$3 }")
if [[ -z $os_name ]]; then
  bosh upload-stemcell \
    ${root_dir}/.stembuild/bosh-stemcell-${stemcell_version}-openstack-kvm-${os_name}-go_agent-raw.tgz

  os_name=$(bosh stemcells | awk "/$stemcell_version/{ print \$3 }")
fi

pushd ${root_dir}/src/stemcells/tests/windows-test-bosh-release

bosh create-release --force
bosh upload-release
bosh -n -d windows-stemcell-test deploy \
  manifest.yml --var=stemcell_os_name=$os_name

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
