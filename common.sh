#!/usr/bin/env bash
# Shared helpers for RoboShop component scripts.
# shellcheck disable=SC2034

set -euo pipefail

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Caller should set SCRIPT_DIR before sourcing; fall back to this file's directory.
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
LOGS_FOLDER="${LOGS_FOLDER:-/var/log/roboshop}"
SCRIPT_NAME="$(basename "$0" .sh)"
LOG_FILE="${LOGS_FOLDER}/${SCRIPT_NAME}.log"
SCRIPT_PATH="${SCRIPT_DIR}"

mkdir -p "$LOGS_FOLDER"

if [[ -f "${SCRIPT_DIR}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/config.env"
fi

: "${DOMAIN_NAME:=roboshop.internal}"
: "${MONGODB_HOST:=mongodb.${DOMAIN_NAME}}"
: "${REDIS_HOST:=redis.${DOMAIN_NAME}}"
: "${MYSQL_HOST:=mysql.${DOMAIN_NAME}}"
: "${RABBITMQ_HOST:=rabbitmq.${DOMAIN_NAME}}"
: "${CATALOGUE_HOST:=catalogue.${DOMAIN_NAME}}"
: "${USER_HOST:=user.${DOMAIN_NAME}}"
: "${CART_HOST:=cart.${DOMAIN_NAME}}"
: "${SHIPPING_HOST:=shipping.${DOMAIN_NAME}}"
: "${PAYMENT_HOST:=payment.${DOMAIN_NAME}}"
: "${MYSQL_ROOT_PASSWORD:=RoboShop@1}"
: "${RABBITMQ_USER:=roboshop}"
: "${RABBITMQ_PASSWORD:=roboshop123}"

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${R}ERROR:${N} run this script as root (sudo)"
    exit 1
  fi
}

VALIDATE() {
  if [[ $1 -ne 0 ]]; then
    echo -e "$2 ${R}Failure${N}"
    exit 1
  fi
  echo -e "$2 ${G}Success${N}"
}

ensure_roboshop_user() {
  if id roboshop &>/dev/null; then
    echo -e "roboshop user already exists... ${Y}SKIPPING${N}"
    return 0
  fi
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  VALIDATE $? "Creating roboshop system user"
}

write_env_file() {
  local dest=$1
  shift
  mkdir -p "$(dirname "$dest")"
  umask 077
  : >"$dest"
  local kv
  for kv in "$@"; do
    printf '%s\n' "$kv" >>"$dest"
  done
  chown root:root "$dest"
  chmod 600 "$dest"
}

echo "script started at: $(date) | log: $LOG_FILE"
