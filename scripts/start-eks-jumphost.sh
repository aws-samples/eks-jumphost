#!/usr/bin/env bash
#
# Start the EKS jumphost instance.

# Error messages
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Set $IFS to only newline and tab
IFS=$'\n\t'

# Strict mode
set -Eeuo pipefail

# Get EKS jumphost instance state
INSTANCE_STATE=$(aws ec2 describe-instances \
  --instance-id "$INSTANCE_ID" \
  --output text \
  --query 'Reservations[].Instances[].State.Name' \
  --region "$REGION")

# Wait for EKS jumphost instance to boot
if [ "$INSTANCE_STATE" == 'running' ]; then
  aws ec2 wait instance-status-ok \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"
elif [ "$INSTANCE_STATE" == 'stopped' ]; then
  aws ec2 start-instances \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"
  aws ec2 wait instance-status-ok \
    --instance-ids "$INSTANCE_ID" \
    --region "$REGION"
else
  echo "Please check instance \"$INSTANCE_ID\" state."
  exit 1
fi
