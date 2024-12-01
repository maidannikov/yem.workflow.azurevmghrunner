#!/bin/bash

# Parameters
JWT=$1
ORGANIZATION=$2

# Validate input
if [ -z "$JWT" ] || [ -z "$ORGANIZATION" ]; then
  echo "Usage: $0 <JWT> <ORGANIZATION>"
  exit 1
fi

# Fetch installation access token URL
INSTALLATION_ACCESS_TOKEN_URL=$(curl -s \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/app/installations | jq -r '.[0].access_tokens_url')

if [ -z "$INSTALLATION_ACCESS_TOKEN_URL" ]; then
  echo "Error: Failed to fetch installation access token URL."
  exit 1
fi

# Fetch installation access token
INSTALLATION_ACCESS_TOKEN=$(curl -s \
  -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  "$INSTALLATION_ACCESS_TOKEN_URL" | jq -r '.token')

if [ -z "$INSTALLATION_ACCESS_TOKEN" ]; then
  echo "Error: Failed to fetch installation access token."
  exit 1
fi

# Fetch registration token
REGISTRATION_TOKEN=$(curl -s \
  -X POST \
  -H "Authorization: Bearer $INSTALLATION_ACCESS_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq -r '.token')

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "Error: Failed to fetch registration token."
  exit 1
fi

# Output only the registration token
echo "$REGISTRATION_TOKEN"
