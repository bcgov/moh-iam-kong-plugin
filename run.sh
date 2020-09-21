#!/bin/bash

# This script uses jq (https://stedolan.github.io/jq/) to parse the JSON, 
# but you could just copy-paste the token value into the script.

CLIENT_ID=kongtest
CLIENT_SECRET=e0e6f385-5084-46c1-a1aa-c03eb646440d

TOKENS=$(curl -s -k -X POST \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "grant_type=client_credentials" \
-d "client_id=${CLIENT_ID}" \
-d "client_secret=${CLIENT_SECRET}" \
https://common-logon-dev.hlth.gov.bc.ca/auth/realms/moh_applications/protocol/openid-connect/token)

ACCESS_TOKEN=$(echo ${TOKENS} | jq -r ".access_token")

echo ${ACCESS_TOKEN}

curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" http://localhost:8000/ \
     --data "${1}"