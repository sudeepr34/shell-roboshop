#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

dnf install maven -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing Maven"
ensure_roboshop_user
mkdir -p /app

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Downloading shipping"
rm -rf /app/*
cd /app
unzip -o /tmp/shipping.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Unzipping shipping"
mvn clean package >>"$LOG_FILE" 2>&1
VALIDATE $? "Building shipping jar"
mv target/*-jar-with-dependencies.jar /app/shipping.jar

write_env_file /etc/roboshop/shipping.env \
  "CART_ENDPOINT=${CART_HOST}:8080" \
  "DB_HOST=${MYSQL_HOST}"

cp "${SCRIPT_PATH}/shipping.service" /etc/systemd/system/shipping.service

dnf install mysql -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing mysql client"
mysql -h "${MYSQL_HOST}" -uroot -p"${MYSQL_ROOT_PASSWORD}" </app/db/schema.sql >>"$LOG_FILE" 2>&1
VALIDATE $? "Loading shipping schema"
mysql -h "${MYSQL_HOST}" -uroot -p"${MYSQL_ROOT_PASSWORD}" </app/db/app-user.sql >>"$LOG_FILE" 2>&1
VALIDATE $? "Loading shipping app user"
mysql -h "${MYSQL_HOST}" -uroot -p"${MYSQL_ROOT_PASSWORD}" </app/db/master-data.sql >>"$LOG_FILE" 2>&1
VALIDATE $? "Loading shipping master data"

systemctl daemon-reload
systemctl enable shipping >>"$LOG_FILE" 2>&1
systemctl restart shipping >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting shipping"
