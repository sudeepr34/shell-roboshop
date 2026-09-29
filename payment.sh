#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

dnf install python3 gcc python3-devel -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing Python"
ensure_roboshop_user
mkdir -p /app

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Downloading payment"
rm -rf /app/*
cd /app
unzip -o /tmp/payment.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Unzipping payment"
pip3 install -r requirements.txt >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing Python deps"

write_env_file /etc/roboshop/payment.env \
  "CART_HOST=${CART_HOST}" \
  "CART_PORT=8080" \
  "USER_HOST=${USER_HOST}" \
  "USER_PORT=8080" \
  "AMQP_HOST=${RABBITMQ_HOST}" \
  "AMQP_USER=${RABBITMQ_USER}" \
  "AMQP_PASS=${RABBITMQ_PASSWORD}"

cp "${SCRIPT_PATH}/payment.service" /etc/systemd/system/payment.service
systemctl daemon-reload
systemctl enable payment >>"$LOG_FILE" 2>&1
systemctl restart payment >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting payment"
