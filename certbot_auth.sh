#!/bin/bash
echo "Logging to Azure..."

if [[ "$SP_ID" == "" ]] ;
then
  echo "Service principal is not given, assuming we are running under managed identity."
  az login --identity
else
  if [[ "$SP_PASS" == "" ]] ; then echo "WARNING: SP_PASS is not provided!" ; fi
  if [[ "$SP_TENANT" == "" ]] ; then echo "WARNING: SP_TENANT is not provided!" ; fi

  echo "Using Service principal $SP_SID to login."
  az login --service-principal -u "$SP_ID" --password "$SP_PASS" --tenant "$SP_TENANT"
fi

if [[ "$DNS_SID" == "" ]] ;
then
  echo "WARNING: No DNS_SID env var is provided!"
  echo "         assuming DNS Zone file and keyvault are in the same subscription."
else
  echo "DNS Subscription id provided: $DNS_SID"
  az account set -s "$DNS_SID"
fi
az account show
echo "Received values from certbot:"
echo " - CERTBOT_VALIDATION: $CERTBOT_VALIDATION"
echo " - CERTBOT_DOMAIN:     $CERTBOT_DOMAIN"
DNS_ZONE_NAME=$(expr match "$CERTBOT_DOMAIN" '.*\.\(.*\..*\)')
echo "Finding out resource group for DNS zone $DNS_ZONE_NAME..."
DNS_ZONE_RG=$(az network dns zone list --query "[?name=='$DNS_ZONE_NAME'].resourceGroup" -o tsv)
echo " - DNS ZONE:           $DNS_ZONE_NAME"
echo " - DNS RG:             $DNS_ZONE_RG"
SUFFIX=".${DNS_ZONE_NAME}"
RECORD_NAME=_acme-challenge.${CERTBOT_DOMAIN%"$SUFFIX"}
echo "Creating record $RECORD_NAME in DNS zone $DNS_ZONE_NAME..."
az network dns record-set txt create -n "$RECORD_NAME" -z "$DNS_ZONE_NAME" -g "$DNS_ZONE_RG" --ttl 30
az network dns record-set txt add-record -n "$RECORD_NAME" -z "$DNS_ZONE_NAME" -g "$DNS_ZONE_RG" -v "$CERTBOT_VALIDATION"
