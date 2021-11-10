#!/bin/bash

export HHOME=/home/crtbot

# Create certificate (optionally using the staging server)
if [[ "$STAGING" == "yes" ]]
then
    echo "Generating cert in staging server..."
    certbot certonly -n -d "$DOMAIN" --manual -m "$EMAIL" --preferred-challenges=dns \
        --config-dir ${HHOME}/config --work-dir ${HHOME}/work --logs-dir ${HHOME}/log \
        --staging --manual-public-ip-logging-ok --agree-tos \
        --manual-auth-hook ${HHOME}/certbot_auth.sh --manual-cleanup-hook ${HHOME}/certbot_cleanup.sh
else
    echo "Generating cert in production server..."
    certbot certonly -n -d "$DOMAIN" --manual -m "$EMAIL" --preferred-challenges=dns \
        --config-dir ${HHOME}/config --work-dir ${HHOME}/work --logs-dir ${HHOME}/log \
        --manual-public-ip-logging-ok --agree-tos \
        --manual-auth-hook ${HHOME}/certbot_auth.sh --manual-cleanup-hook ${HHOME}/certbot_cleanup.sh
fi
# If debugging, show created certificates
if [[ "$DEBUG" == "yes" ]]
then
    ls -al "/etc/letsencrypt/live/${DOMAIN}/"
    cat "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    cat "/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
    cat "/var/log/letsencrypt/letsencrypt.log"
fi
# Variables to create AKV cert
pem_file="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
key_file="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
cert_name=$(echo "$DOMAIN" | tr -d '.')

# Combine PEM and key in one pfx file (pkcs#12)
pfx_file=".${pem_file}.pfx"
openssl pkcs12 -export -in "$pem_file" -inkey "$key_file" -out "$pfx_file" -passin pass:"$key_password" -passout pass:"$key_password"
#
if [[ "$KEYVAULT_SID" == "" ]] ;
then
  echo "WARNING: No KEYVAULT_SID env var is provided!"
  echo "         assuming DNS Zone file and keyvault are in the same subscription."
else
  echo "Keyvault subscription id provided: $KEYVAULT_SID"
  az account set -s "$KEYVAULT_SID"
fi
# Add certificate
if [[ "$DEBUG" == "yes" ]]
then
  echo "Keyvault name to use: $AKV"
  echo "CertName to create: $cert_name"
fi
az keyvault certificate import --vault-name "$AKV" -n "$cert_name" -f "$pfx_file"

