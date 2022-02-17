#!/usr/bin/env bash
#
# Execute a script via the EKS jumphost.

# Error messages
trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR

# Set $IFS to only newline and tab
IFS=$'\n\t'

# Strict mode
set -Eeuo pipefail

# Open SSH tunnel
TEMP_DIR=$(mktemp -d)
ssh-keygen -t rsa -N '' -f "$TEMP_DIR"/key
aws ec2-instance-connect send-ssh-public-key \
    --instance-id "$INSTANCE_ID" \
    --instance-os-user ec2-user \
    --region "$REGION" \
    --ssh-public-key file://"$TEMP_DIR"/key.pub
ssh ec2-user@"$INSTANCE_ID" -D "$LOCAL_PORT" -Nf \
  -i "$TEMP_DIR"/key \
  -o IdentitiesOnly=yes \
  -o ProxyCommand="aws ssm start-session \
    --document-name AWS-StartSSHSession \
    --parameters 'portNumber=22' \
    --region \"$REGION\" \
    --target \"$INSTANCE_ID\"" \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null

# Replace the section between ### SCRIPT ###
# if you want to run this script manually
### SCRIPT ###
# shellcheck disable=SC2154
${script}
### SCRIPT ###

# Close SSH tunnel
pkill -f "$INSTANCE_ID"
aws ssm terminate-session \
  --region "$REGION" \
  --session-id "$(aws ssm describe-sessions \
    --filters key=Target,value="$INSTANCE_ID" \
    --output text \
    --query "Sessions[].SessionId" \
    --region "$REGION" \
    --state Active)"
