#!/bin/bash

echo "Installing required dependencies..."

# Install jq
sudo apt-get update
sudo apt-get install -y jq curl tar build-essential gawk bison

# Install jwt-cli
echo "Installing jwt-cli..."
curl -L https://github.com/mike-engel/jwt-cli/releases/download/6.2.0/jwt-linux.tar.gz -o jwt-cli.tar.gz
tar -xvzf jwt-cli.tar.gz
sudo mv jwt /usr/local/bin/jwt
chmod +x /usr/local/bin/jwt
echo "All dependencies installed successfully."