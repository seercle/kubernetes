#!/usr/bin/env bash

set -o pipefail
client_id=$1 # Client ID as first argument

pem=$( cat $2 ) # file path of the private key as second argument

now=$(date +%s)
iat=$((${now} - 60)) # Issues 60 seconds in the past
exp=$((${now} + 600)) # Expires 10 minutes in the future

b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

header_json='{
    "typ":"JWT",
    "alg":"RS256"
}'
# Header encode
header=$( echo -n "${header_json}" | b64enc )

payload_json="{
    \"iat\":${iat},
    \"exp\":${exp},
    \"iss\":\"${client_id}\"
}"
# Payload encode
payload=$( echo -n "${payload_json}" | b64enc )

# Signature
header_payload="${header}"."${payload}"
signature=$(
    openssl dgst -sha256 -sign <(echo -n "${pem}") \
    <(echo -n "${header_payload}") | b64enc
)

# Create JWT
JWT="${header_payload}"."${signature}"
printf '%s\n' "JWT: $JWT"

# Now we can use the JWT to retrieve installation IDs

API_URL="https://api.github.com/app/installations"

echo "Attempting to retrieve GitHub App installation IDs..."
echo "----------------------------------------------------"

curl -s --fail \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github.v3+json" \
  "${API_URL}" | jq '.[] | {id: .id, account_login: .account.login, account_type: .account.type}'

if [ $? -ne 0 ]; then
  echo "----------------------------------------------------"
  echo "Error: Failed to retrieve installation IDs."
  echo "Please ensure your JWT is valid and has the necessary permissions (e.g., 'Read' access to 'Administration' or 'Metadata')."
  echo "Also, check your internet connection and GitHub API status."
fi

echo "----------------------------------------------------"
echo "Script finished."
