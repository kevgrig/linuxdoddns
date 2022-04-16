#!/bin/sh

echoPrefix() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] ${@}"
}

echoFinish() {
  echoPrefix "linuxdodns Finished"
}

echoPrefix "linuxdodns version 0.1.20220416"

DOTOKEN="$(cat /etc/linuxdodns.pwd)"
if [ -z "${DOTOKEN}" ]; then
  echoPrefix "Missing Digital Ocean API token file /etc/linuxdodns.pwd"
  exit 1
fi

if [ -z "${1}" ]; then
  echoPrefix "Missing domain argument"
  exit 1
fi

DOMAIN="$(echo "${1}" | awk -F. '{ printf("%s.%s", $(NF-1), $NF); }')"
SUBDOMAIN="$(echo "${1}" | awk -F. '{ printf("%s", $1); }')"

if [ -z "${SUBDOMAIN}" ]; then
  echoPrefix "Missing subdomain"
  exit 1
fi

echoPrefix "Processing ${SUBDOMAIN}.${DOMAIN}"

echoPrefix "Requesting current public IP"

PUBLICIPSOURCE="https://ipinfo.io/ip"
PUBLICIP="$(curl --silent ${PUBLICIPSOURCE})"

if [ -z "${PUBLICIP}" ]; then
  echoPrefix "Could not query public IP from ${PUBLICIPSOURCE}"
  exit 1
fi

echoPrefix "Public IP is ${PUBLICIP}"

# https://docs.digitalocean.com/reference/api/api-reference/#operation/list_all_domain_records
# https://docs.digitalocean.com/reference/api/api-reference/#section/Introduction/Links-and-Pagination

DOQUERY="$(curl --silent --request GET --header "Content-Type: application/json" \
                --header "Authorization: Bearer ${DOTOKEN}" \
                "https://api.digitalocean.com/v2/domains/${DOMAIN}/records?type=A&per_page=200" | \
                jq ".domain_records[] | select(.name==\"${SUBDOMAIN}\") | {id,data}")"

if [ -z "${DOQUERY}" ]; then
  echoPrefix "Failed to query the DNS record"
  exit 1
fi

#echoPrefix "Digital Ocean query result: ${DOQUERY}"

DORECORD="$(echo "${DOQUERY}" | awk '/"id"/ { gsub(/,/, "", $NF); print $NF; }')"
if [ -z "${DORECORD}" ]; then
  echoPrefix "Failed to find the record ID"
  exit 1
fi

echoPrefix "Digital Ocean record ID: ${DORECORD}"

DODATA="$(echo "${DOQUERY}" | awk '/"data"/ { gsub(/"/, "", $NF); print $NF; }')"
if [ -z "${DODATA}" ]; then
  echoPrefix "Failed to find the current IP"
  exit 1
fi

echoPrefix "Digital Ocean current IP: ${DODATA}"

if [ "${DODATA}" = "${PUBLICIP}" ]; then
  echoPrefix "Skipping update of ${SUBDOMAIN}.${DOMAIN} A record because it is already set to ${PUBLICIP}"
  echoFinish
  exit 0
fi

# https://docs.digitalocean.com/reference/api/api-reference/#operation/update_domain_record
DOUPDATE="$(curl --silent -v -X PUT --header "Content-Type: application/json" \
            --header "Authorization: Bearer ${DOTOKEN}" -d "{\"data\":\"${PUBLICIP}\"}" \
            --write-out "\n%{http_code}" \
            "https://api.digitalocean.com/v2/domains/${DOMAIN}/records/${DORECORD}" 2>&1)"

if [ -z "${DOUPDATE}" ]; then
  echoPrefix "Failed to update the DNS record"
  exit 1
fi

#echoPrefix "Digital Ocean update result: ${DOUPDATE}"

DOUPDATESTATUS="$(echo "${DOUPDATE}" | awk '{ last=$0; } END { print last; }')"
if [ -z "${DOUPDATESTATUS}" ]; then
  echoPrefix "Failed to find the update status code"
  exit 1
fi

echoPrefix "Digital Ocean update status code: ${DOUPDATESTATUS}"

if [ "${DOUPDATESTATUS}" != "200" ]; then
  echoPrefix "Error updating record:"
  echo "${DOUPDATE}"
  exit 1
fi

echoPrefix "Successfully updated ${SUBDOMAIN}.${DOMAIN} A record to ${PUBLICIP}"

echoFinish
