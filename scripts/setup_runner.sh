#!/bin/bash

# Parameters
while [ "$1" != "" ]; do
    case $1 in
        --subscription-id ) shift
                            SUBSCRIPTION_ID=$1
                            ;;
        --resource-group )  shift
                            RESOURCE_GROUP=$1
                            ;;
        --location )        shift
                            LOCATION=$1
                            ;;
        --vm-size )         shift
                            VM_SIZE=$1
                            ;;
        --runner-group )    shift
                            RUNNER_GROUP=$1
                            ;;
        --runner-labels )   shift
                            RUNNER_LABELS=$1
                            ;;
        --admin-username )  shift
                            VM_USER=$1
                            ;;
        --organization )    shift
                            ORGANIZATION=$1
                            ;;
        --registration-token ) shift
                            RUNNER_TOKEN=$1
                            ;;
        * )                 echo "Error: Invalid parameter: $1"
                            exit 1
    esac
    shift
done

VM_IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
VM_NAME="${ORGANIZATION}-azure-vm-$(date +%s)"
SSH_KEY="$HOME/.ssh/github_runner_key"
GITHUB_URL="https://github.com/$ORGANIZATION"         
RUNNER_NAME="runner-${VM_NAME}"              
RUNNER_WORK_DIR="_work"

# Check if the resource group exists or create it
echo "Checking if the resource group ${RESOURCE_GROUP} exists..."
az group show --name "${RESOURCE_GROUP}" --subscription "${SUBSCRIPTION_ID}" --output table 2>/dev/null
if [ $? -ne 0 ]; then
  echo "Resource group ${RESOURCE_GROUP} not found. Creating it..."
  az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}" --subscription "${SUBSCRIPTION_ID}" --output table
  if [ $? -ne 0 ]; then
    echo "Failed to create the resource group ${RESOURCE_GROUP}. Exiting."
    exit 1
  fi
  echo "Resource group ${RESOURCE_GROUP} created successfully."
else
  echo "Resource group ${RESOURCE_GROUP} exists. Proceeding."
fi

# Generate SSH keys
if [ ! -f "${SSH_KEY}" ]; then
  echo "Generating SSH keys..."
  ssh-keygen -t rsa -b 2048 -f "${SSH_KEY}" -N ""
else
  echo "SSH key already exists: ${SSH_KEY}"
fi

# Create the virtual machine
echo "Creating the virtual machine ${VM_NAME}..."
az vm create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --image "${VM_IMAGE}" \
  --size "${VM_SIZE}" \
  --admin-username "${VM_USER}" \
  --ssh-key-values "${SSH_KEY}.pub" \
  --output table

# Get the public IP address of the virtual machine
VM_IP=$(az vm show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${VM_NAME}" \
  --show-details \
  --query publicIps -o tsv)

if [ -z "$VM_IP" ]; then
  echo "Failed to retrieve the public IP address of the virtual machine."
  exit 1
fi
echo "The virtual machine has been created."
echo "Public IP address: ${VM_IP}"

echo "Checking the version of the GitHub Runner..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
if [ -z "$LATEST_VERSION" ]; then
    echo "Error: Failed to get the latest version of the GitHub Runner."
    exit 1
fi
echo "Latest version: $LATEST_VERSION"

REMOTE_COMMANDS=$(cat <<EOF
#!/bin/bash

RUNNER_VERSION="$LATEST_VERSION"
RUNNER_NAME="$RUNNER_NAME"
RUNNER_WORK_DIR="$RUNNER_WORK_DIR"
GITHUB_URL="$GITHUB_URL"
RUNNER_TOKEN="$RUNNER_TOKEN"
RUNNER_GROUP="$RUNNER_GROUP"
RUNNER_LABELS="$RUNNER_LABELS"

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl tar wget apt-transport-https software-properties-common

# Install PowerShell Core
echo "Installing PowerShell Core..."
wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
pwsh --version || { echo "Failed to install PowerShell Core"; exit 1; }

echo "Creating the actions-runner directory..."
mkdir -p actions-runner
cd actions-runner

echo "Downloading GitHub Runner version \$RUNNER_VERSION..."
curl -o actions-runner-linux-x64-\$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v\$RUNNER_VERSION/actions-runner-linux-x64-\$RUNNER_VERSION.tar.gz

echo "Extracting GitHub Runner..."
tar xzf actions-runner-linux-x64-\$RUNNER_VERSION.tar.gz
rm actions-runner-linux-x64-\$RUNNER_VERSION.tar.gz

echo "Setting up the runner..."
./config.sh --url "\$GITHUB_URL" --token "\$RUNNER_TOKEN" --name "\$RUNNER_NAME" --work "\$RUNNER_WORK_DIR" --unattended --replace --runnergroup "\$RUNNER_GROUP" --labels "\$RUNNER_LABELS"

echo "Setting up the runner as a service..."
sudo ./svc.sh install
sudo ./svc.sh start

echo "GitHub Runner has been installed and started!"
EOF
)


echo "Connecting to the virtual machine $VM_IP..."
ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$VM_USER@$VM_IP" "$REMOTE_COMMANDS"