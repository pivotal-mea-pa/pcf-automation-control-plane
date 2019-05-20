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

if [[ ! -e ${root_dir}/.config/templates ]]; then
  mkdir -p ${root_dir}/.config/templates

  find ${root_dir}/src/pipelines/config/templates/ -maxdepth 1 -name '*' \
    -exec cp {} ${root_dir}/.config/templates \;
  find ${root_dir}/src/pipelines/config/templates/${iaas}/ -maxdepth 1 -name '*' \
    -exec cp {} ${root_dir}/.config/templates \;

  for i in $(seq 0 $((num_foundations-1))); do
    name=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/name)

    mkdir -p ${root_dir}/.config/foundations/${name}/env
    mkdir -p ${root_dir}/.config/foundations/${name}/vars
    mkdir -p ${root_dir}/.config/foundations/${name}/state
    touch ${root_dir}/.config/foundations/${name}/state/.keep

    find ${root_dir}/src/pipelines/config/foundations/env/ -maxdepth 1 -name '*' \
      -exec cp {} ${root_dir}/.config/foundations/${name}/env \;
    find ${root_dir}/src/pipelines/config/foundations/vars/ -maxdepth 1 -name '*' \
      -exec cp {} ${root_dir}/.config/foundations/${name}/vars \;
    find ${root_dir}/src/pipelines/config/foundations/vars/${iaas}/ -maxdepth 1 -name '*' \
      -exec cp {} ${root_dir}/.config/foundations/${name}/vars \;
  done

  pushd ${root_dir}/.config

  git config user.name "automation"
  git config push.default simple
  git add .
  git commit -m "initial"
  git push
fi
