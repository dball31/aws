# Script Name: Transit Gateway Route Export Script

## Overview
This script retrieves route information from AWS Transit Gateway (TGW) route tables and exports the data to a CSV file. The output file contains details such as CIDR blocks, attachment IDs, and route table names.

---

## Prerequisites
- **AWS CLI**: Ensure the AWS CLI is installed and configured with appropriate credentials and permissions.
- **jq** installed for parsing JSON output.

---

## Usage
1. Save the script to a file, for example, tgw_routes.sh.
2. Make the script executable:
  - chmod +x tgw_routes.sh
3. Run the script:
  - ./tgw_routes.sh

---

## Output

The script generates a CSV file named tgw_routes.csv with the following format:

CIDR,AttachmentID,RouteTableName
192.168.1.0/24,tgw-attach-12345678,RouteTable-1
10.0.0.0/16,tgw-attach-87654321,RouteTable-2

---

## License
This script is open-source and provided as-is without any warranty. Use at your own risk.