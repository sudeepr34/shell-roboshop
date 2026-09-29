#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"
require_root

cp -p "${SCRIPT_PATH}/rabbitmq.repo" /etc/yum.repos.d/rabbitmq.repo
dnf install rabbitmq-server -y >>"$LOG_FILE" 2>&1
VALIDATE $? "Installing RabbitMQ"

systemctl enable rabbitmq-server >>"$LOG_FILE" 2>&1
VALIDATE $? "Enabling RabbitMQ"
systemctl start rabbitmq-server >>"$LOG_FILE" 2>&1
VALIDATE $? "Starting RabbitMQ"

if ! rabbitmqctl list_users | awk '{print $1}' | grep -qx "${RABBITMQ_USER}"; then
  rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASSWORD}" >>"$LOG_FILE" 2>&1
  VALIDATE $? "Creating RabbitMQ user"
fi
rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*" >>"$LOG_FILE" 2>&1
VALIDATE $? "Granting RabbitMQ permissions"
