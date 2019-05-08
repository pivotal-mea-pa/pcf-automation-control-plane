#!/bin/bash

set -eux

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

  mkdir -p ${root_dir}/.config/config
  mkdir -p ${root_dir}/.config/foundations/sandbox/vars
  mkdir -p ${root_dir}/.config/foundations/sandbox/env
  mkdir -p ${root_dir}/.config/foundations/sandbox/state

  touch ${root_dir}/.config/config/.keep
  touch ${root_dir}/.config/foundations/sandbox/vars/.keep
  touch ${root_dir}/.config/foundations/sandbox/env/.keep
  touch ${root_dir}/.config/foundations/sandbox/state/.keep

  pushd ${root_dir}/.config

  git config user.name "automation"
  git config push.default simple
  git add .
  git commit -m "initial"
  git push
fi
