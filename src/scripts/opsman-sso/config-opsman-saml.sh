#!/bin/bash -u

set -xeu
root_dir=$(cd $(dirname "$(ls -l $0 | awk '{ print $NF }')")/.. && pwd)

curl  -k "https://${OM_TARGET}/api/v0/setup" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "setup": {
      "identity_provider": "saml",
      "decryption_passphrase": "'$OM_DECRYPTION_PASSPHRASE'",
      "decryption_passphrase_confirmation": "'$OM_DECRYPTION_PASSPHRASE'",
      "idp_metadata": "'$UAA_TARGET'/saml/idp/metadata",
      "bosh_idp_metadata": "'$UAA_TARGET'/saml/idp/metadata",
      "eula_accepted": "true",
      "create_bosh_admin_client": true
    }
  }'

sleep 10
om curl -p "/uaa/saml/metadata" -o om-sp-metadata.xml

${root_dir}/src/scripts/create_saml_sp.sh -i \
  -t "$UAA_TARGET" \
  -c "$UAA_ADMIN_CLIENT" \
  -p "$UAA_ADMIN_CLIENT_SECRET" \
  -n "om" \
  -m ${root_dir}/.state/om-sp-metadata.xml \
  -s "https://${OM_TARGET}:443/uaa"
