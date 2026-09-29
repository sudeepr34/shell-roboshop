#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

cp "${SCRIPT_PATH}/mongo.repo" /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding MongoDB yum repo"

dnf install mongodb-org -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing MongoDB"

systemctl enable mongod >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling mongod"

systemctl start mongod >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting mongod"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote MongoDB connections"

systemctl restart mongod >>"$LOG_FILE" 2>&1
VALIDATE $? "Restarting mongod"
