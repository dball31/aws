# Script Name: AWS Control Tower - Resource Verification

## Overview
This script is designed to verify AWS resources, including Landing Zone, Organizational Units (OUs), and Service Control Policies (SCPs), within a Management Account. It collects and outputs relevant data about the AWS environment to an output file, providing an organized summary of key AWS resources created by AWS Control Tower.

The script is interactive and allows the user to specify whether to collect extended details about the AWS environment. The verification of AWS resources will always run, but specific actions will depend on the user's input.

---

## Features
- Verifies AWS resource information.
- Able to retrieve and output details about:
  - Landing Zone ARN and Home Region.
  - Organizational Units (OUs).
  - AWS Account Information.
  - Enabled SCPs for each OU.
- Saves all output to a specified file for documentation and review.
- Dynamically handles conditional execution based on user input, specifically, the script will ask if it is collecting data in the Management account.

---

## Prerequisites
- **AWS CLI**: Ensure that the AWS Command Line Interface (CLI) is installed and configured.
- **JQ**: This script uses `jq` for parsing JSON output from AWS CLI commands.
- **AWS IAM Permissions**: If collecting Organization infromation within the Management account, nsure you have the necessary permissions to execute the following AWS CLI commands:
  - `aws controltower list-landing-zones`
  - `aws controltower get-landing-zone`
  - `aws organizations list-roots`
  - `aws organizations list-organizational-units-for-parent`
  - `aws organizations list-accounts`
  - `aws controltower list-enabled-controls`
- **Account Access**: The script can be executed within any AWS account, but will display a prompt asking if the user is logged into the Management account.  If the user answers "Yes", the script will execute additional commands to retrieve information about the AWS Organization.

---

## Usage
1. Clone or download the script to your local environment.
2. Open a terminal and navigate to the directory containing the script.
3. Execute the script using:
   ```bash
   ./script_name.sh
   ```
4. The script will prompt you to answer the following question:
   - **"Do you want to collect extended details about the AWS environment? (Yes/No)"**
     - **Yes**: Collects extended details about Landing Zone, OUs, Accounts, and SCPs.
     - **No**: Skips the extended collection, but still verifies AWS resources. **Script defaults to 'No' after 10 seconds**
5. The script outputs the results to the specified file, which can be customized by editing the `output_file` variable.

---

## Script Flow
1. **Verify AWS Resources**:
   - This section always runs regardless of the user's input.
   - Ensures the script can access required AWS resources and outputs basic information.
2. **Conditional Execution**:
   - If the user answers "Yes", the script retrieves and outputs additional details:
     - Landing Zone ARN and Home Region.
     - OU information.
     - AWS Account Information.
     - Enabled SCPs for each OU.
   - If the user answers "No", this section is skipped.
3. **Output**:
   - The collected information is appended to the output file for review and documentation.

---

## Example Output
The output file includes structured information such as:
- **Landing Zone Information**:
  ```
  ---BEGIN AWS Landing Zone Information---
  { "arn": "arn:aws:controltower:us-east-1::landing-zone/example" }
  ---END AWS Landing Zone Information---
  ```
- **OU Information**:
  ```
  ---BEGIN AWS OU Information---
  OrganizationalUnit1 \t OUName1
  OrganizationalUnit2 \t OUName2
  ---END AWS OU Information---
  ```
- **AWS Account Information**:
  ```
  ---BEGIN AWS Account Information---
  | Id          | Email              | Name       | Status |
  |------------ |------------------- |----------- |--------|
  | 1234567890  | example@email.com  | Account1   | ACTIVE |
  ---END AWS Account Information---
  ```
- **Enabled SCPs per OU**:
  ```
  ---BEGIN List of Enabled SCPs per OU---
  OrganizationalUnit1, SCPName1
  OrganizationalUnit2, SCPName2
  ---END List of Enabled SCPs per OU---
  ```

---

## Notes
- This script is intended for informational purposes and does not make any changes to the AWS environment.
- Ensure all dependencies are installed before running the script.
- Always review the output file to confirm the accuracy and completeness of the information collected.

---

## Troubleshooting
- **Permission Errors**:
  - Ensure you are logged into the AWS CLI with a user or role that has sufficient permissions.
- **Missing Dependencies**:
  - Verify that both AWS CLI and `jq` are installed and available in your PATH.
- **Invalid Output**:
  - Confirm that your AWS CLI configuration points to the correct Management Account and region.

---

## License
This script is open-source and provided "as is" without warranty. Use it at your own risk.

