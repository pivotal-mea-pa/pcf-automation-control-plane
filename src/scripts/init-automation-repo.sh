#!/bin/bash

set -eux

num_foundations=$(bosh interpolate ${root_dir}/vars.yml --path /number_foundations)

if [[ $local_git_server == yes \
  && ! -e /home/git/pcf-configuration.git ]]; then

  # Create repository in local host that can serve as 
  # a remote git repository for pcf configurations

  set +e
  sudo userdel git > /dev/null 2>&1
  set -e
  sudo rm -fr /home/git

  sudo useradd git -m -d /home/git -s /bin/bash
  sudo mkdir -p /home/git/.ssh
  sudo cp $HOME/.ssh/git.pem.pub /home/git/.ssh/authorized_keys
  sudo git init --bare /home/git/pcf-configuration.git
  sudo chown -R git:git /home/git
fi

rm -fr ${root_dir}/.config
git clone $automation_git_repo_path ${root_dir}/.config

if [[ ! -e ${root_dir}/.config/config/.keep ]]; then

  cp -r ${root_dir}/src/pipelines/config/templates .config

  for i in $(seq 0 $((num_foundations-1))); do
    name=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/name)

    mkdir -p ${root_dir}/.config/foundations/${name}/vars
    cp ${root_dir}/src/pipelines/config/foundations/vars/opsman-${iaas}.yml \
      ${root_dir}/.config/foundations/${name}/vars/opsman/opsman.yml

    cp -r ${root_dir}/src/pipelines/config/foundations/env \
      ${root_dir}/.config/foundations/${name}
  done

  pushd ${root_dir}/.config

  git config user.name "automation"
  git config push.default simple
  git add .
  git commit -m "initial"
  git push
fi

[[ $set_foundation_creds != yes ]] || \
  source ${root_dir}/src/scripts/set-foundation-creds.sh
