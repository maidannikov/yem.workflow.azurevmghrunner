#!/bin/bash

# Parameters
JWT=$1  # JWT для аутентификации
ORG=$2  # Название GitHub организации

# Validate input
if [ -z "$JWT" ] || [ -z "$ORG" ]; then
  echo "Usage: $0 <JWT> <ORG>"
  exit 1
fi

echo "Fetching installation access token URL..."

# Fetch installation access token URL
INSTALLATION_ACCESS_TOKEN_URL=$(curl -s \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/app/installations | jq -r '.[0].access_tokens_url')

if [ -z "$INSTALLATION_ACCESS_TOKEN_URL" ]; then
  echo "Error: Failed to fetch installation access token URL."
  exit 1
fi

echo "Fetching installation access token..."

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

echo "Fetching registration token..."

# Fetch registration token
REGISTRATION_TOKEN=$(curl -s \
  -X POST \
  -H "Authorization: Bearer $INSTALLATION_ACCESS_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/$ORG/actions/runners/registration-token | jq -r '.token')

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "Error: Failed to fetch registration token."
  exit 1
fi
