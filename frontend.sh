#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

dnf module disable nginx -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Disabling default nginx"
dnf module enable nginx:1.24 -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling nginx:1.24"
dnf install nginx -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing nginx"

systemctl enable nginx >>"$LOG_FILE" 2>&1
systemctl start nginx >>"$LOG_FILE" 2>&1

rm -rf /usr/share/nginx/html/*
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Downloading frontend"
cd /usr/share/nginx/html
unzip -o /tmp/frontend.zip >>"$LOG_FILE" 2>&1
VALIDATE $? "Unzipping frontend"

sed \
  -e "s/catalogue\.roboshop\.internal/${CATALOGUE_HOST}/g" \
  -e "s/user\.roboshop\.internal/${USER_HOST}/g" \
  -e "s/cart\.roboshop\.internal/${CART_HOST}/g" \
  -e "s/shipping\.roboshop\.internal/${SHIPPING_HOST}/g" \
  -e "s/payment\.roboshop\.internal/${PAYMENT_HOST}/g" \
  "${SCRIPT_PATH}/nginx.conf" >/etc/nginx/nginx.conf
VALIDATE $? "Installing nginx.conf"

systemctl restart nginx >>"$LOG_FILE" 2>&1
VALIDATE $? "Restarting nginx"
