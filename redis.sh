#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

dnf module disable redis -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Disabling default redis module"
dnf module enable redis:7 -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling redis:7"
dnf install redis -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Allowing remote Redis connections"

systemctl enable redis >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling redis"
systemctl start redis >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting redis"
