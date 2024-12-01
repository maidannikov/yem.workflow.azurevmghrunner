#!/bin/bash

# Parameters
APP_KEY_BASE64=$1  # Base64-encoded private key
APP_ID=$2          # GitHub App ID

# Validate input
if [ -z "$APP_KEY_BASE64" ] || [ -z "$APP_ID" ]; then
  echo "Error: Missing required parameters."
  exit 1
fi

# Decode the private key
PRIVATE_KEY_PATH="/tmp/github-app-key.pem"
echo -n "$APP_KEY_BASE64" | base64 -d > "$PRIVATE_KEY_PATH"

# Validate the private key
if ! openssl rsa -in "$PRIVATE_KEY_PATH" -check > /dev/null 2>&1; then
  echo "Error: Private key is invalid."
  rm "$PRIVATE_KEY_PATH"
  exit 1
fi

# Generate JWT
ISS=$APP_ID
IAT=$(date +%s)
EXP=$(date -d "+10 minutes" +%s)

JWT=$(jwt encode \
  --secret "@$PRIVATE_KEY_PATH" \
  --payload "iss=$ISS" \
  --payload "iat=$IAT" \
  --payload "exp=$EXP" \
  --alg RS256) || { echo "Error: Failed to generate JWT."; rm "$PRIVATE_KEY_PATH"; exit 1; }

# Clean up and output only the JWT
rm "$PRIVATE_KEY_PATH"
echo "$JWT"
