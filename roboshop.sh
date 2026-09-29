#!/usr/bin/env bash
# Bootstrap EC2 instances + Route53 A records for each RoboShop component.
# Usage: sudo -E ./roboshop.sh mongodb redis mysql rabbitmq catalogue user cart shipping payment frontend

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

: "${AMI_ID:?Set AMI_ID in config.env}"
: "${SG_ID:?Set SG_ID in config.env}"
: "${ZONE_ID:?Set ZONE_ID in config.env}"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <component> [component...]"
  exit 1
fi

for instance in "$@"; do
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance}}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
  VALIDATE $? "Launching ${instance}"

  # Wait until private (and public for frontend) IPs are assigned.
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  if [[ "$instance" != "frontend" ]]; then
    IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    RECORD_NAME="${instance}.${DOMAIN_NAME}"
  else
    IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
      --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    RECORD_NAME="${DOMAIN_NAME}"
  fi

  echo "${instance} = ${IP} -> ${RECORD_NAME}"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Comment\": \"UPSERT ${RECORD_NAME}\",
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${RECORD_NAME}\",
          \"Type\": \"A\",
          \"TTL\": 60,
          \"ResourceRecords\": [{\"Value\": \"${IP}\"}]
        }
      }]
    }"
  VALIDATE $? "Route53 UPSERT ${RECORD_NAME}"
done
