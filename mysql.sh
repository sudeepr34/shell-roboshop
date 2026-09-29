#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

dnf install mysql-server -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing MySQL"
systemctl enable mysqld >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling mysqld"
systemctl start mysqld >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting mysqld"

mysql_secure_installation --set-root-pass "${MYSQL_ROOT_PASSWORD}" >>"$LOG_FILE" 2>&1
VALIDATE $? "Setting MySQL root password"
