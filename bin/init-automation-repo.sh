#!/bin/bash

set -e

auto_config_repo_path=$1
if [[ ! -e $auto_config_repo_path ]]; then
  echo "Automation repository path must be provided as the first argument."
  exit 1
fi

# auto_config_repo_git_url=$2
# if [[ ! -e $auto_config_repo_git_url ]]; then
#   echo "Automation repository git URL must be provided as the second argument."
#   exit 1
# fi

mkdir -p $auto_config_repo_path
pushd $auto_config_repo_path

# if [[ ! -e $auto_config_repo_path ]]; then
#   git init
#   git remote add origin $auto_config_repo_git_url
# else
#   git pull
# fi

mkdir -p ${auto_config_repo_path}/