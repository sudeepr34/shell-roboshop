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
VALIDATE $? "Creating /app"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Downloading catalogue"
rm -rf /app/*
cd /app
unzip -o /tmp/catalogue.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Unzipping catalogue"
npm install >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing npm dependencies"

write_env_file /etc/roboshop/catalogue.env \
  "MONGO=true" \
  "MONGO_URL=mongodb://${MONGODB_HOST}:27017/catalogue"

cp "${SCRIPT_PATH}/catalogue.service" /etc/systemd/system/catalogue.service
VALIDATE $? "Installing catalogue unit"

cp "${SCRIPT_PATH}/mongo.repo" /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing mongosh"

INDEX=$(mongosh "${MONGODB_HOST}" --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')" || echo "-1")
if [[ "${INDEX}" -lt 0 ]]; then
  mongosh --host "${MONGODB_HOST}" </app/db/master-data.js >>"$LOG_FILE" 2>&1
  VALIDATE $? "Loading catalogue master data"
else
  echo -e "Catalogue DB already present... ${Y}SKIPPING${N}"
fi

systemctl daemon-reload
systemctl enable catalogue >>"$LOG_FILE" 2>&1
systemctl restart catalogue >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting catalogue"
