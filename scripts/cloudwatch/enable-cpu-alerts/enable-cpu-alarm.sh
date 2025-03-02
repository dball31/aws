#!/bin/bash

#---
#--- CPU Utilization Alerts
#--- Sets up an SNS topic (SNS_TOPIC_NAME) - set this value to align with organizational policies
#--- Change the notification email to the address which should receive the alerts
#--- This script creates CPU Utilization Alarms (70%) for EC2 instances tagged with EnableAlarms=Yes
#---

# Set log file in the script's directory
LOG_FILE="ec2_alarm_creation.log"
AWS_REGION="us-east-1"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting EC2 CloudWatch Alarm management script..."

# Get AWS Account Number
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
  log_message "ERROR: Failed to retrieve AWS account ID."
  exit 1
fi

#---
#--- Set SNS topic
#---
SNS_TOPIC_NAME="cpu-utilization-alerts"
SNS_TOPIC_ARN="arn:aws:sns:${AWS_REGION}:${AWS_ACCOUNT_ID}:${SNS_TOPIC_NAME}"

# Check if SNS topic exists, otherwise create it
EXISTING_TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn, '$SNS_TOPIC_NAME')].TopicArn" --output text)
if [ -z "$EXISTING_TOPIC_ARN" ]; then
  log_message "Creating SNS topic: $SNS_TOPIC_NAME"
  SNS_TOPIC_ARN=$(aws sns create-topic --name "$SNS_TOPIC_NAME" --query "TopicArn" --output text)
else
  SNS_TOPIC_ARN=$EXISTING_TOPIC_ARN
  log_message "Using existing SNS topic: $SNS_TOPIC_ARN"
fi


#---
#--- Set notification email (change this!)
#---
EMAIL="david.ball@cdw.com"

# Subscribe email if not already subscribed
SUBSCRIBED=$(aws sns list-subscriptions-by-topic --topic-arn "$SNS_TOPIC_ARN" --query "Subscriptions[?Endpoint=='$EMAIL'].SubscriptionArn" --output text)
if [ -z "$SUBSCRIBED" ]; then
  log_message "Subscribing email to SNS topic: $EMAIL"
  aws sns subscribe --topic-arn "$SNS_TOPIC_ARN" --protocol email --notification-endpoint "$EMAIL"
  log_message "Check your email and confirm the subscription."
else
  log_message "Email already subscribed to SNS topic."
fi

# Get all EC2 Instance IDs with EnableAlarms=Yes
# Change to match your preferred tag
TAGGED_INSTANCES=($(aws ec2 describe-instances \
  --filters "Name=tag:EnableAlarms,Values=Yes" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text))

# Get all existing CloudWatch alarms for EC2 instances
EXISTING_ALARMS=($(aws cloudwatch describe-alarms \
  --query "MetricAlarms[?starts_with(AlarmName, 'High-CPU-')].AlarmName" --output text))

# Create alarms for tagged instances if they don't exist
for INSTANCE_ID in "${TAGGED_INSTANCES[@]}"; do
  ALARM_NAME="High-CPU-${INSTANCE_ID}"
  if [[ ! " ${EXISTING_ALARMS[@]} " =~ " ${ALARM_NAME} " ]]; then
    log_message "Creating CloudWatch Alarm for instance: $INSTANCE_ID"
    aws cloudwatch put-metric-alarm \
      --alarm-name "$ALARM_NAME" \
      --metric-name "CPUUtilization" \
      --namespace "AWS/EC2" \
      --statistic "Average" \
      --period 300 \
      --evaluation-periods 2 \
      --threshold 70 \
      --comparison-operator "GreaterThanThreshold" \
      --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
      --alarm-actions "$SNS_TOPIC_ARN" \
      --alarm-description "Triggers when CPU usage exceeds 70% for instance $INSTANCE_ID" \
      --unit "Percent"
    log_message "Alarm created: $ALARM_NAME"
  else
    log_message "Alarm already exists for instance: $INSTANCE_ID"
  fi
done

# Remove alarms for instances that no longer have the tag
for ALARM_NAME in "${EXISTING_ALARMS[@]}"; do
  INSTANCE_ID=${ALARM_NAME#"High-CPU-"}
  
  # Check if the instance still exists and is tagged
  if [[ ! " ${TAGGED_INSTANCES[@]} " =~ " ${INSTANCE_ID} " ]]; then
    log_message "Removing CloudWatch Alarm: $ALARM_NAME (Instance no longer tagged)"
    aws cloudwatch delete-alarms --alarm-names "$ALARM_NAME"
    log_message "Alarm removed: $ALARM_NAME"
  fi
done

log_message "CloudWatch alarm management complete!"
