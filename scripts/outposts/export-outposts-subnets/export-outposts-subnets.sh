#!/bin/bash

# Initialize an associative array to store Outpost details and subnet information
declare -A outpost_subnet_map

# Retrieve Outpost Names and ARNs
outpost_data=$(aws outposts list-outposts --query "Outposts[*].[Name,OutpostArn]" --output text)

# Debug: Log retrieved Outpost Names and ARNs
echo "Retrieved Outpost Data (Name and ARN): $outpost_data"

# Check if any Outpost data was found
if [[ -z "$outpost_data" ]]; then
  echo "No Outposts found. Exiting."
  exit 1
fi

# Loop through each Outpost Name and ARN pair
while read -r outpost_name outpost_arn; do
  echo "Processing Outpost: $outpost_name ($outpost_arn)"  # Debug message

  # Retrieve subnet details (ID, CIDR block, EnableLniAtDeviceIndex, Tags) associated with the Outpost
  subnets=$(aws ec2 describe-subnets --filters "Name=outpost-arn,Values=$outpost_arn" \
    --query "Subnets[].[SubnetId, CidrBlock, EnableLniAtDeviceIndex, Tags]" --output json)

  # Debug: Log the raw JSON output of the describe-subnets command
  echo "Subnets JSON for Outpost $outpost_name ($outpost_arn): $subnets"

  # Check if any subnets were found
  if [[ -z "$subnets" || "$subnets" == "[]" ]]; then
    echo "No subnets found for Outpost: $outpost_name ($outpost_arn)"
    continue
  fi

  # Add all subnet data to the mapping, using the Outpost Name and ARN as the key
  outpost_subnet_map["$outpost_name ($outpost_arn)"]="$subnets"
done <<< "$outpost_data"

# Write the results to a file
output_file="outpost_subnet_mapping.txt"
echo "Outpost Name and ARN to Subnet Data Mapping:" | tee $output_file

# Check if the associative array has any data
if [[ ${#outpost_subnet_map[@]} -eq 0 ]]; then
  echo "No subnets found. Output file will remain empty." | tee -a $output_file
  exit 1
fi

for outpost_key in "${!outpost_subnet_map[@]}"; do
  echo "Outpost: $outpost_key" | tee -a $output_file
  echo "Subnets:" | tee -a $output_file
  echo -e "${outpost_subnet_map[$outpost_key]}" | tee -a $output_file
  echo "" | tee -a $output_file
done

echo "Output written to $output_file"
