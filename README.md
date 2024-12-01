# **GitHub Self-Hosted Runner on Azure**

This repository contains a workflow to deploy a self-hosted GitHub Actions runner on an Azure virtual machine. The runner is configured to connect to a specified GitHub repository or organization and is suitable for various CI/CD workloads.

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
| `runner_group`     | GitHub Runner Group                               | ✔️ Yes       | `'Performance'`               | Specify the group in your GitHub organization. |
| `runner_labels`    | Custom labels for the GitHub runner               | ✔️ Yes       | `'performance,vm,azure'`      | Use labels for job targeting.                 |
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
