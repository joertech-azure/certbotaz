#!/bin/bash

if [[ -z $AKV || -z $CERTNAME || -z $DOMAIN || -z $EMAIL ]]; then
  echo 'one or more variables are undefined'
  exit 1
fi

export HHOME=/home/crtbot

# Login to Azure

echo "Login to Azure..."

if [[ "$SP_ID" == "" ]] ;
then
  echo "SP_ID not set, assuming we run with managed identity."
  az login --identity
else
  if [[ "$SP_PASS" == "" ]] ; then echo "WARNING: SP_PASS is not provided!" ; fi
  if [[ "$SP_TENANT" == "" ]] ; then echo "WARNING: SP_TENANT is not provided!" ; fi

  echo "Using Service principal to login."
  az login --service-principal -u "$SP_ID" --password "$SP_PASS" --tenant "$SP_TENANT"
fi
#

# Create certificate (optionally using the staging server)
if [[ "$STAGING" == "yes" ]]
then
    echo "Generating cert in staging server..."
    certbot certonly --authenticator dns-azure --dns-azure-config ${HHOME}/azure.ini -n -d "$DOMAIN" -m "$EMAIL" --preferred-challenges=dns \
        --config-dir ${HHOME}/letsencrypt --work-dir ${HHOME}/work --logs-dir ${HHOME}/logs \
        --staging --manual-public-ip-logging-ok --agree-tos
else
    echo "Generating cert in production server..."
    certbot certonly --authenticator dns-azure --dns-azure-config ${HHOME}/azure.ini -n -d "$DOMAIN" -m "$EMAIL" --preferred-challenges=dns \
        --config-dir ${HHOME}/letsencrypt --work-dir ${HHOME}/work --logs-dir ${HHOME}/logs \
        --manual-public-ip-logging-ok --agree-tos
fi

DIR=$(echo "${DOMAIN}" | sed 's/^\*\.//')

# If debugging, show created certificates
if [[ "$DEBUG" == "yes" ]]
then
    ls -al "${HHOME}/letsencrypt/live/${DIR}/"
    cat "${HHOME}/letsencrypt/live/${DIR}/fullchain.pem"
    cat "${HHOME}/logs/letsencrypt.log"
fi

# Variables to create AKV cert
pem_file="${HHOME}/letsencrypt/live/${DIR}/fullchain.pem"
key_file="${HHOME}/letsencrypt/live/${DIR}/privkey.pem"

# Combine PEM and key in one pfx file (pkcs#12)
pfx_file="${pem_file}.pfx"
openssl pkcs12 -export -in "$pem_file" -inkey "$key_file" -out "$pfx_file" -passin pass:"$key_password" -passout pass:"$key_password"

if [[ "$KEYVAULT_SID" == "" ]] ;
then
  echo "WARNING: No KEYVAULT_SID env var is provided!"
  echo "         assuming DNS Zone file and keyvault are in the same subscription."
else
  echo "Keyvault subscription id provided: $KEYVAULT_SID"
  az account set -s "$KEYVAULT_SID"
fi

# Add certificate to KV
if [[ "$DEBUG" == "yes" ]]
then
  echo "Keyvault name to use: $AKV"
fi
az keyvault certificate import --vault-name "$AKV" -n "$CERTNAME" -f "$pfx_file"

