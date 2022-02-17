#!/usr/bin/env bash
#
# Stop the EKS jumphost instance.

# Error messages
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Set $IFS to only newline and tab
IFS=$'\n\t'

# Strict mode
set -Eeuo pipefail

# Stop eks-jumphost instance
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"
aws ec2 wait instance-stopped \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION"
