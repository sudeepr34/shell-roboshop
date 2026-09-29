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

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Downloading user"
rm -rf /app/*
cd /app
unzip -o /tmp/user.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Unzipping user"
npm install >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing npm dependencies"

write_env_file /etc/roboshop/user.env \
  "MONGO=true" \
  "REDIS_URL=redis://${REDIS_HOST}:6379" \
  "MONGO_URL=mongodb://${MONGODB_HOST}:27017/users"

cp "${SCRIPT_PATH}/user.service" /etc/systemd/system/user.service
systemctl daemon-reload
systemctl enable user >>"$LOG_FILE" 2>&1
systemctl restart user >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting user"
