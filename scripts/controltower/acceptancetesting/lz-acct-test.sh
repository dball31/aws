#!/bin/bash

#---Retrieve the Current AWS Account ID
account_number=$(aws sts get-caller-identity --query "Account" --output text)

#---Create the CSV file dynamically using the account number
output_file="ct-atp-$account_number.csv"

#---Create the CSV repository
echo "---BEGIN AWS CONTROL TOWER ACCEPTANCE TEST PLAN (ATP)" > $output_file
echo "" >> $output_file
echo "" >> $output_file

#---Verify AWS Resources in the Account
verify_aws_resources() {
    #---Retrieve the Current AWS Account ID
    account_number=$(aws sts get-caller-identity --query "Account" --output text)

    #---List Control Tower IAM roles
    echo "---BEGIN IAM Roles in the logged-in AWS Account $account_number---" >> $output_file
    aws iam list-roles --query 'Roles[?starts_with(RoleName, `aws-controltower`) || starts_with(RoleName, `AWSControlTower`)].RoleName' --output table >> $output_file
    echo "---END IAM Roles in the logged-in AWS Account $account_number---" >> $output_file
    echo "" >> $output_file

    #---Verify CloudTrail is Logging
    echo "---BEGIN CloudTrail Logging Verification---" >> $output_file
    ct_trail_arn=$(aws cloudtrail list-trails --output json | jq -r '.Trails[] | select(.Name == "aws-controltower-BaselineCloudTrail") | .TrailARN')
    is_logging=$(aws cloudtrail get-trail-status --name $ct_trail_arn --query 'IsLogging' --output text)
    echo "IsLogging,$is_logging" >> $output_file
    echo "---END CloudTrail Logging Verification---" >> $output_file
    echo "" >> $output_file

    #---Check Status of CloudFormation Stacks in AWS Accounts
    echo "---BEGIN CloudFormation Stack Check for AWS Account $account_number---" >> $output_file
    aws cloudformation describe-stacks --query "Stacks[*].[StackName, StackStatus]" --output table >> $output_file
    echo "---END CloudFormation Stack Check for AWS Account $account_number---" >> $output_file
    echo "" >> $output_file

    #---Verify the Lambda Function aws-controltower-NotificationForwarder has been created
    echo "---BEGIN AWS Control Tower - Lambda Functions List---" >> $output_file
    aws lambda list-functions --output json | \
    jq -r '.Functions[] | select(.FunctionName | contains("ControlTower")) | [.FunctionName, .FunctionArn] | @csv' >> $output_file
    echo "---END AWS Control Tower - Lambda Functions List---" >> $output_file
    echo "" >> $output_file

    #---Verify the SNS Topic aws-controltower-SecurityNotifications has been created
    echo "---BEGIN AWS Control Tower - SNS Topics List---" >> $output_file
    aws sns list-topics --output json | \
    jq -r '.Topics[] | select(.TopicArn | contains("aws-controltower")) | [.TopicArn, .DisplayName] | @csv' >> $output_file
    echo "---END AWS Control Tower - SNS Topics List---" >> $output_file
    echo "" >> $output_file
}

#---Prompt the user to confirm if they are logged into the Management Account
echo "Are you logged into the AWS Management Account? (Yes/No)"
read -t 10 user_input

# Check if user_input is empty (timeout occurred)
if [[ -z "$user_input" ]]; then
  echo "No input detected within 10 seconds. Defaulting to 'No'."
  user_input="No"
fi

#---Execute AWS Organizational Checks if logged into the Management Account
if [[ "$user_input" == "Yes" || "$user_input" == "yes" ]]; then
  #---Obtain the Landing Zone ARN and Home Region---
  landing_zone_arn=$(aws controltower list-landing-zones --output json | jq -r '.landingZones[0].arn')

  #---Extract the Landing Zone Home Region | Use as 'landing_zone_region' variable
  landing_zone_region=$(echo $landing_zone_arn | awk -F':' '{print $4}')

  #---Get Landing Zone Information | Populate the --landing-zone-identifier with the 'arn' value from the landing_zone_arn command | save output to $output_file
  echo "---BEGIN AWS Landing Zone Information---" >> $output_file
  aws controltower get-landing-zone --landing-zone-identifier $landing_zone_arn --output json >> $output_file
  echo "---END AWS Landing Zone Information" >> $output_file
  echo "" >> $output_file

  #---Retrieve the Root OU ID to create OU List | Use as $root_ou_id variable
  echo "---BEGIN AWS OU Information---" >> $output_file
  root_ou_id=$(aws organizations list-roots --output json | jq -r '.Roots[0].Id')

  #---Retrieve Organizational Units for the Root OU
  #---Extract the AWS Account ID for use as 'aws_acct_id' variable
  #---Create 'aws_org_arn' as a means to include only necessary data in CSV file using 'sub' argument
  ou_info=$(aws organizations list-organizational-units-for-parent --parent-id $root_ou_id --output json)
  aws_acct_id=$(echo "$ou_info" | jq -r '.OrganizationalUnits[0].Arn | split(":")[4]')
  aws_org_arn="arn:aws:organizations::$aws_acct_id:"

  #---Save OU Information to $output_file
  echo "$ou_info" | jq -r --arg aws_org_arn "$aws_org_arn" '.OrganizationalUnits[] | [ (.Arn | sub($aws_org_arn; "")), .Name ] | @tsv' >> $output_file
  echo "---END AWS OU Information---" >> $output_file
  echo "" >> $output_file

  #---Save AWS Account Information to $output_file
  echo "---BEGIN AWS Account Information---" >> $output_file
  aws organizations list-accounts --output table --query 'Accounts[*].[Id, Email, Name, Status]' >> $output_file
  echo "---END AWS Account Information---" >> $output_file
  echo "" >> $output_file

  #---Generates and appends the list of Enabled SCPs per OU to $output_file 
  echo "---BEGIN List of Enabled SCPs per OU---" >> $output_file
  while IFS= read -r ou; do
      ou_arn=$(echo $ou | jq -r '.Arn')
      ou_name=$(echo $ou | jq -r '.Name')
      
      #---Construct the Control Tower ARN dynamically
      ct_arn="arn:aws:controltower:$landing_zone_region::control/"

      aws controltower list-enabled-controls --target-identifier $ou_arn --output json | \
      jq -r --arg aws_org_arn "$aws_org_arn" --arg ou_name "$ou_name" --arg ct_arn "$ct_arn" \
      '.enabledControls[] | [ (.targetIdentifier | sub($aws_org_arn; "")), $ou_name, .controlIdentifier | sub($ct_arn; "") ]' | \
      jq -s -r --arg separator "," 'map(join($separator))' >> $output_file
  done <<< "$(echo $ou_info | jq -c '.OrganizationalUnits[]')"
  echo "---END List of Enabled SCPs per OU---" >> $output_file
  echo "" >> $output_file
else
  echo "Skipping execution of Control Tower Organization checks as you're not logged into the AWS Management Account."
fi

#---Always run the verify_aws_resources function
verify_aws_resources

echo "End Script"
