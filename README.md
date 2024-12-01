# **GitHub Self-Hosted Runner on Azure**

This repository contains a workflow to deploy a self-hosted GitHub Actions runner on an Azure virtual machine. The runner is configured to connect to a specified GitHub repository or organization and is suitable for various CI/CD workloads.

---

## **Requirements**
### **GitHub App Setup**
To use this workflow, you must have a GitHub App with the following setup:
- Navigate to Settings > Developer Settings > GitHub Apps.
- Create a new GitHub App with the following organization permissions:
    - Self-hosted runners: Read & Write
    - Metadata: Read
- After creating the app, generate a Private Key
    - Download the private key file
    - Base64-encode the private key
    ```bash
    cat <private-key.pem> | base64 -w0 
    ```
- Store the following details as GitHub secrets in your repository
    - APP_ID: The App ID of your GitHub App
    - APP_KEY: The Base64-encoded private key
### **Azure Credentials**    
You need to provide Azure credentials as a secret in your repository for the workflow to interact with Azure resources.
- Create a Service Principal with appropriate permissions:
    - The Contributor role is required to manage Azure resources like VMs and resource groups.
    ```bash
    az ad sp create-for-rbac --name "GitHubRunnerSP" --role contributor --scopes /subscriptions/<subscription-id> --sdk-auth
    # Replace <subscription-id> with your Azure Subscription ID.
    ```
- Copy the output JSON securely and store it as a GitHub secret:
    - AZURE_SP: Paste the entire JSON output as the value of this secret.
Example JSON:

    ```json
    {
      "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
      "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
      "resourceManagerEndpointUrl": "https://management.azure.com/",
      "activeDirectoryGraphResourceId": "https://graph.windows.net/",
      "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
      "galleryEndpointUrl": "https://gallery.azure.com/",
      "managementEndpointUrl": "https://management.core.windows.net/"
    }
    
    ```

---

## **Features**
- 🔄 Dynamically creates an Azure VM for the runner.
- 🔒 Configures and registers the runner using GitHub App authentication.
- 🌍 Supports multiple VM sizes and regions.
- 🏷️ Offers custom labels for targeting workflows.
- 🗝️ Securely uploads SSH keys as artifacts for debugging (optional).
- 🛠️ Includes installation of PowerShell Core for additional scripting capabilities.

---

## **Workflow Parameters**

| **Parameter**      | **Description**                                   | **Required** | **Default Value**            | **Options / Notes**                            |
|--------------------|---------------------------------------------------|--------------|------------------------------|------------------------------------------------|
| `subscription_id`  | Azure Subscription ID                             | ✔️ Yes       | `'your-default-subscription-id'` | Provide your Azure subscription ID.           |
| `resource_group`   | Azure Resource Group                              | ✔️ Yes       | `'github-runner-rg'`          | Existing or new resource group.               |
| `location`         | Azure Location                                    | ✔️ Yes       | `'uksouth'`                    | Use any valid Azure region (e.g., `westeurope`, `uksouth`). |
| `vm_size`          | Azure VM Size                                     | ✔️ Yes       | `'Standard_B1s'`              | Choose from `Standard_B1s`, `Standard_D2s_v3`, `Standard_F4s_v2`. |
| `runner_group`     | GitHub Runner Group                               | ✔️ Yes       | `'YourRunnerGroupName'`               | Specify the group in your GitHub organization. |
| `runner_labels`    | Custom labels for the GitHub runner               | ✔️ Yes       | `'bestrunner,vm,azure'`      | Use labels for job targeting.                 |
| `admin_username`   | Admin username for Azure VM                       | ✔️ Yes       | `'azureuser'`                 | Username for SSH access.                      |
| `organization`     | GitHub organization where the runner will be registered | ✔️ Yes       | `'your-organization'`    | Specify the organization name.                |
| `upload_ssh_key`   | Upload SSH key as artifact for debugging          | ❌ No        | `'false'`                     | `true` to upload the SSH key.                 |

---

## **Usage**

### **Trigger the Workflow**

1. Navigate to the **Actions** tab in your GitHub repository.
2. Select the **"Create Azure VM Runner"** workflow.
3. Click **Run Workflow**.
4. Fill in the required parameters or use defaults.

---

## **Setup Details**

### 🛠️ **Dependencies Installed**
- Installs `jq`, `jwt-cli` on the GitHub-hosted runner.

### 🔐 **Runner Configuration**
- Generates a JWT for secure GitHub App authentication.
- Fetches the registration token for the runner.
- Registers the runner to the specified GitHub organization and group.

### 💻 **Azure VM**
- Automatically creates the VM in the specified resource group and location.
- Configures the runner with custom labels for workflow targeting.
- Installs PowerShell Core on the Azure VM.
- Enables SSH access for debugging purposes.

---

## **Debugging the Runner**

### 📂 **Download the SSH Key**
- If `upload_ssh_key=true`, retrieve the key from the workflow artifacts.

### 🖧 **Connect to the VM**
1. Retrieve the VM's public IP from the workflow logs or Azure portal.
2. Connect to the VM using SSH:
   ```bash
   ssh -i github_runner_key azureuser@<vm-public-ip>
   ```
