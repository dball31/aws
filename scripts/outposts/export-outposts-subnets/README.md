# Script Name: AWS Outposts - Subnet Export Script

## Overview 
This script retrieves details about AWS Outposts and their associated subnets, such as subnet ID, CIDR block, and LNI settings, and outputs the information into a structured file. It leverages the AWS CLI to interact with the AWS Outposts and EC2 services.

---

## Features
- Fetches a list of Outposts and their ARNs using the AWS CLI.
- Retrieves details about subnets associated with each Outpost, including:
  - Subnet ID
  - CIDR Block
  - EnableLniAtDeviceIndex settings
  - Tags
-Maps Outpost names and ARNs to their subnet data.
-Writes the results to a file named outpost_subnet_mapping.txt.

---

##Prerequisites
- **AWS CLI**: Ensure the AWS CLI is installed and configured with appropriate credentials and permissions.
  - Permissions:
     - `outposts:ListOutposts`
     - `ec2:DescribeSubnets`
- **Access to Outposts and Subnet Resources**: Ensure the AWS account has Outposts and associated subnets available.

---

## Usage
1. Save the script to a file, for example, outpost_subnet_mapping.sh.
2. Make the script executable:
  - chmod +x outpost_subnet_mapping.sh
3. Run the script:
  - ./outpost_subnet_mapping.sh

---

## Output

The script outputs the subnet data for each Outpost to both the console and a file named outpost_subnet_mapping.txt. If no Outposts or subnets are found, the script exits with an appropriate message.

## Output

The output file `outpost_subnet_mapping.txt` contains mappings of Outpost names and ARNs to their associated subnets. Example:

Outpost Name and ARN to Subnet Data Mapping:
Outpost: 1 (arn:aws:outposts:us-east-2:123456789011:outpost/op-0db23s7mc345tyssh)  
Subnets:
```json
[
    [
        "subnet-123b6dc43cq2334fd",
        "192.168.1.0/24",
        null,
        [
            {
                "Key": "Name",
                "Value": "subnet1"
            }
        ]
    ],
    [
        "subnet-32123tt3k39zyx4d4",
        "172.16.1.0/24",
        1,
        [
            {
                "Key": "Name",
                "Value": "lni-subnet1"
            }
        ]
    ]
]
```

---

## Script Details / Key Steps
- **Retrieve Outpost Information**: The script uses aws outposts list-outposts to get a list of Outpost names and ARNs.
- **Fetch Subnet Details**: For each Outpost, it uses aws ec2 describe-subnets with a filter for the outpost-arn.
- **Store Results in an Associative Array**: Maps the Outpost name and ARN to its associated subnet data.
- **Write Results to File**: Outputs the mapping to a structured file for easy reference.

---

## Debugging
The script includes debug messages that:
- Log the retrieved Outpost data.
- Show the raw JSON output of the describe-subnets command for each Outpost.

---

## Error Handling
-Exits with a message if no Outposts are found.
-Skips Outposts that have no associated subnets.

---

## Notes
-Ensure the AWS CLI is configured with the correct region, as the script relies on the default region setting.
-The script only processes subnets explicitly associated with Outposts using the outpost-arn filter.

---

## License
This script is open-source and provided as-is without any warranty. Use at your own risk.