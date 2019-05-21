#!/bin/bash

# Global return value from functions
fn_ret_val=

# Injects the keys from a YAML file as environment.
# The keys will be capitalized when exported to the
# environment.
function yaml_to_env() {

  yaml_file=$1

  eval $(python <<EOL
import yaml, sys 
vars=yaml.load(open('$yaml_file', 'r'))
for k,v in vars.items():
    print("export {}='{}'".format(k.upper(), v))
EOL
)
}

function set_credhub_value() {
  set -e
  fn_ret_val=

  # Args
  local name="$1"
  local value="$2"
  local overwrite="${3:-yes}"

  # Check if value exists if overwrite is 'no'
  if [[ $overwrite == no ]]; then

    set +e
    fn_ret_val=$(credhub get -q -n "$name" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      set -e
      return
    fi
    set -e
  fi

  credhub set -n "$name" -t value -v "$value"
  fn_ret_val="$value"
}

function set_credhub_password() {
  set -e
  fn_ret_val=

  # Args
  local name="$1"
  local value="$2"
  local regenerate="${3:-yes}"

  # Check if value exists if regenerate is 'no'
  if [[ $regenerate == no ]]; then

    set +e
    fn_ret_val=$(credhub get -q -n "$name" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      set -e
      return
    fi
    set -e
  fi

  if [[ "$value" == "*" ]]; then
    credhub generate -n "$name" -t password
    fn_ret_val=$(credhub get -q -n "$name" 2>/dev/null)
  else
    credhub set -n "$name" -t password -w "$value"
    fn_ret_val="$value"
  fi
}

function generate_credhub_certificate() {
  set -e
  fn_ret_val=

  # Args
  local name="$1"
  local regenerate="${2:-no}"
  local root_ca_ref="$3"
  local common_name="$4"
  local alternative_names="$5"
  local organization="$6"

  # Check if value exists if regenerate is 'no'
  if [[ $regenerate == no ]]; then

    set +e
    fn_ret_val=$(credhub get -j -n "$name" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
      set -e
      return
    fi
    set -e
  fi

  alternative_name_args=""
  for an in $(echo "$alternative_names" | sed 's|,| |g'); do 
    alternative_name_args="$alternative_name_args -a $an"
  done

  credhub generate -n "$name" -t certificate \
    -d 3650 \
    --ca "$root_ca_ref" \
    -c "$common_name" \
    $alternative_name_args \
    -o "$organization" \
    -u "" -i "" -s "" -y ""

  fn_ret_val=$(credhub get -j -n "$name" 2>/dev/null)
}