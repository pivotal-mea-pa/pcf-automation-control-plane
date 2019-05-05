#!/bin/bash -eu

set -eu

automation_git_repo_path=$(bosh interpolate ${root_dir}/vars.yml --path /automation_git_repo_path)
automation_git_private_key=$(bosh interpolate ${root_dir}/vars.yml --path /automation_git_private_key)

if [[ ! -e $automation_git_repo_path ]]; then
  echo "Automation repository git URL not provided as the second argument so a repo will be created locally."
  
  set +e
  sudo userdel git > /dev/null 2>&1
  set -e
  sudo rm -fr /home/git

  rm $HOME/.ssh/git.pem*
  ssh-keygen -t rsa -b 4096 -N "" -f $HOME/.ssh/git.pem

  sudo useradd git -m -d /home/git -s /bin/bash
  sudo mkdir -p /home/git/.ssh
  sudo cp $HOME/.ssh/git.pem.pub /home/git/.ssh/authorized_keys
  sudo git init --bare /home/git/pcf-configuration.git
  sudo chown -R git:git /home/git

  local_itf=$(ip a | awk '/^[0-9]+: (eth|ens?)[0-9]+:/{ print substr($2,1,length($2)-1) }' | head -1)
  local_ip=$(ifconfig $local_itf | awk '/inet addr:/{ print substr($2,6) }')

  set +e
  grep "Host $local_ip" $HOME/.ssh/config >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then

    touch $HOME/.ssh/config
    cat << ---EOF >> $HOME/.ssh/config

Host $local_ip
  AddKeysToAgent yes
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  IdentityFile $HOME/.ssh/git.pem
---EOF

  fi
  set -e

  automation_git_repo_path=git@${local_ip}:pcf-configuration.git
  echo "*** Initializing local automation repo: $automation_git_repo_path"
fi

rm -fr ${root_dir}/.config
git clone $auto_repo_path ${root_dir}/.config

mkdir -p ${root_dir}/.config/config
mkdir -p ${root_dir}/.config/foundations/default/vars
mkdir -p ${root_dir}/.config/foundations/default/env
mkdir -p ${root_dir}/.config/foundations/default/state

touch ${root_dir}/.config/config/.keep
touch ${root_dir}/.config/foundations/default/vars/.keep
touch ${root_dir}/.config/foundations/default/env/.keep
touch ${root_dir}/.config/foundations/default/state/.keep
git add .
git commit -m "initial"
git push
