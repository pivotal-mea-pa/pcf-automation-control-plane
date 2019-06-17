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
  sudo git init --bare /home/git/pcf-state.git
  sudo chown -R git:git /home/git
fi

rm -fr ${pcf_config_repo_path}
git clone $automation_config_repo_path ${pcf_config_repo_path}
rm -fr ${pcf_state_repo_path}
git clone $automation_state_repo_path ${pcf_state_repo_path}

if [[ ! -e ${pcf_config_repo_path}/templates ]]; then
  mkdir -p ${pcf_config_repo_path}/templates

  # Populate config and state repositories with initial templates

  find ${root_dir}/src/pipelines/config/templates/ -maxdepth 1 -name '*' \
    -exec cp {} ${pcf_config_repo_path}/templates \;
  find ${root_dir}/src/pipelines/config/templates/${iaas}/ -maxdepth 1 -name '*' \
    -exec cp {} ${pcf_config_repo_path}/templates \;

  for i in $(seq 0 $((num_foundations-1))); do
    name=$(bosh interpolate ${root_dir}/vars.yml --path /foundations/$i/name)

    mkdir -p ${pcf_config_repo_path}/foundations/${name}/env
    mkdir -p ${pcf_config_repo_path}/foundations/${name}/vars
    mkdir -p ${pcf_state_repo_path}/foundations/${name}/state
    touch ${pcf_state_repo_path}/foundations/${name}/state/.keep

    find ${root_dir}/src/pipelines/config/foundations/env/ -maxdepth 1 -name '*' \
      -exec cp {} ${pcf_config_repo_path}/foundations/${name}/env \;
    find ${root_dir}/src/pipelines/config/foundations/vars/ -maxdepth 1 -name '*' \
      -exec cp {} ${pcf_config_repo_path}/foundations/${name}/vars \;
    find ${root_dir}/src/pipelines/config/foundations/vars/${iaas}/ -maxdepth 1 -name '*' \
      -exec cp {} ${pcf_config_repo_path}/foundations/${name}/vars \;
  done

  pushd ${pcf_config_repo_path}

  git config user.name "automation"
  git config push.default simple
  git add .
  git commit -m "initial"
  git push
fi
