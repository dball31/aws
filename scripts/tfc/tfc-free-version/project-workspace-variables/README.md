# 🚀 Terraform Cloud Project & Workspace & Workspace Variable Creation Script

tfc-pwvar.sh is a bash script that automates the setup of a **Terraform Cloud project**, **workspace**, and **workspace-level variables** via the TFC API. It has been primarily used with organizations new to HCP Terraform and are thus using the free edition.

---

## 📦 Features

- ✅ Idempotent creation of a **Terraform Cloud Project**
- ✅ Idempotent creation of a **Workspace** (with retry logic)
- ✅ Injection of **Terraform or Environment variables** (with sensitive flag support)
- ✅ All operations performed via the [Terraform Cloud API](https://developer.hashicorp.com/terraform/cloud-docs/api-docs)

---

## 🔧 Requirements

- A [Terraform Cloud](https://app.terraform.io) account
- A valid **Terraform Cloud API token** with access to your organization
- [`jq`](https://stedolan.github.io/jq/) for JSON parsing
- [`curl`](https://curl.se/) for API requests
- Bash shell (macOS, Linux, WSL, or Git Bash on Windows)

---

## ⚙️ Configuration

At the top of the script, set the following variables:

```bash
ORG_NAME="your-tfc-org"                 # Terraform Cloud organization name
PROJECT_NAME="tfc-project-name"         # Name of the project to create or reuse
WORKSPACE_NAME="tfc-workspace-name"     # Name of the workspace to create or reuse
API_TOKEN="$TFC_TOKEN"                  # Set this as an environment variable beforehand
```
### 🔐 Set your API token securely:

```bash
export TFC_TOKEN-"your-tfc-cloud-api-token"     # Set this as an environment variable before running the script
```
You can use the `tfc-token-check.sh` script within the repo to perform a token check to verify you have the permissions to complete the project-workspace-variable script. 

### 📌 Variable Definition Format:

Update the TF_VARS array to define your desired workspace variables.<br>
Entries follow this format: **key|value|sensitive|category**

| Field | Description |
|-------|-------------|
| <a name="key"></a> [key](#input\_key) | Name of the variable |
| <a name="value"></a> [value](#input\_value) | Value assigned to the variable |
| <a name="sensitive"></a> [sensitive](#input\_sensitive) | `true` to hide the value in TFC UI and API; `false` to show |
| <a name="category"></a> [category](#input\_category) | `terraform` (for Terraform variables) or `env` (for Environment variables) |

```bash
TF_VARS=(
  "region|us-east-1|false|terraform"
  "AWS_ACCESS_KEY_ID|abc123|true|env"
  "AWS_SECRET_ACCESS_KEY|xyz456|true|env"
  "vpc_id|vpc-1234567890123456|false|terraform"
)
```
## ▶️ Usage

1. Clone or download the script:

2. Make the script executable:

```bash
chmod +x tfc-token-check.sh         # If you want to run the TFC token check
chmod +x tfc-pwvar.sh
```
3. Export your TFC API token:

```bash
export TFC_TOKEN-"your-tfc-cloud-api-token"
```
4. Run the script(s):

```bash
./tfc-token-check.sh                # If no errors on the token check, run tfc-pwvar.sh
./tfc-pwvar.sh
```
### 📃 Sample Output

```text
🔍 Checking for project: tfc-project-name
✅ Found existing project 'tfc-project-name' with ID: prj-abc123
🔍 Checking if workspace 'tfc-workspace-name' exists...
⚙️ Creating workspace 'tfc-workspace-name' in project 'tfc-project-name'...
✅ Workspace 'tfc-workspace-name' created successfully (ID: ws-xyz789)
📌 Adding variables directly to workspace: tfc-workspace-name
📦 Creating variable: region (category: terraform, sensitive: false)
✅ Variable 'region' created successfully.
🎉 Done!
```

## ✅ Terraform Cloud API Token Validation Script

This script verifies that a **Terraform Cloud API token** has sufficient access to:

- The specified Terraform Cloud **organization**
- The **Projects API**
- The **Workspaces API**

It's intended as a **pre-check** before running automation scripts that create or modify projects and workspaces using the Terraform Cloud API.

---

### 🎯 Purpose

Ensure that the `TFC_TOKEN` environment variable:

- Is set
- Has access to the specified organization
- Can interact with required Terraform Cloud APIs

This helps prevent automation failures by validating API access up front.

---

### 🧪 Sample Output

```text
🔍 Verifying access to organization 'your-tfc-org'...
✅ Organization access confirmed.
🔍 Checking access to Projects API...
✅ Projects API access confirmed.
🔍 Checking access to Workspaces API...
✅ Workspaces API access confirmed.
🎯 Token is valid and has sufficient access for project + workspace script.
```

### ❌ Common Errors

If TFC_TOKEN has not been specified, is invalid, or missing permissions, you will see the following:

- TFC_TOKEN environment variable is not set
- Cannot access organization 'your-tfc-org'. HTTP Status: 401
- Cannot access Projects API. Check token permissions. HTTP Status: 403