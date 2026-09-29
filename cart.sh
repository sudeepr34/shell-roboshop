#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

dnf module disable nodejs -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Disabling default nodejs"
dnf module enable nodejs:20 -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling nodejs:20"
dnf install nodejs -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing nodejs"

ensure_roboshop_user
mkdir -p /app

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Downloading cart"
rm -rf /app/*
cd /app
unzip -o /tmp/cart.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Unzipping cart"
npm install >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing npm dependencies"

write_env_file /etc/roboshop/cart.env \
  "REDIS_HOST=${REDIS_HOST}" \
  "CATALOGUE_HOST=${CATALOGUE_HOST}" \
  "CATALOGUE_PORT=8080"

cp "${SCRIPT_PATH}/cart.service" /etc/systemd/system/cart.service
systemctl daemon-reload
systemctl enable cart >>"$LOG_FILE" 2>&1
systemctl restart cart >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting cart"
