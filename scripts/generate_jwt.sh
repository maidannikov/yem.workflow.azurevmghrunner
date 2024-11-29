#!/bin/bash

# Parameters
APP_KEY_BASE64=$1  # Base64-encoded private key
APP_ID=$2          # GitHub App ID

# Validate input
if [ -z "$APP_KEY_BASE64" ] || [ -z "$APP_ID" ]; then
  echo "Usage: $0 <APP_KEY_BASE64> <APP_ID>"
  exit 1
fi

# Decode the private key
echo "Decoding private key..."
echo -n "$APP_KEY_BASE64" | base64 -d > /tmp/github-app-key.pem

# Validate the private key
if ! openssl rsa -in /tmp/github-app-key.pem -check > /dev/null 2>&1; then
  echo "Error: Private key is invalid."
  rm /tmp/github-app-key.pem
  exit 1
fi

# Generate JWT
echo "Generating JWT..."
ISS=$APP_ID
IAT=$(date +%s)
EXP=$(date -d "+10 minutes" +%s)

JWT=$(jwt encode \
  --secret "@/tmp/github-app-key.pem" \
  --payload "iss=$ISS" \
  --payload "iat=$IAT" \
  --payload "exp=$EXP" \
  --alg RS256) || { echo "Error: Failed to generate JWT."; rm /tmp/github-app-key.pem; exit 1; }

# Clean up the private key
rm /tmp/github-app-key.pem

# Output the JWT
echo "$JWT"
