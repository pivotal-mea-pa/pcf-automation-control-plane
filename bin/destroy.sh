#!/bin/bash

set -e

bosh delete-env \
  --state .state/cp-state.json \
  --vars-store .state/cp-creds.yml \
  .state/cp-manifest.yml
