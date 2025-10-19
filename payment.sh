#!/bin/bash

R="\e[31m"
G="\e[32m"
y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=172.31.22.68
REDIS_HOST=172.31.23.81
MYSQL_HOST=172.31.26.67
RABBITMQ_HOST=172.31.28.64
USER_HOST=172.31.21.18
CART_HOST=172.31.23.203
CATALOGUE_HOST=172.31.27.108
SHIPPING_HOST=172.31.23.140
SCRIPT_PATH=$PWD
START_TIME=$(date +%s)


mkdir -p $LOGS_FOLDER
echo "script started execution at: $(date)"

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo "ERROR: Please run this script with root access"
    exit 1 # failure is other than 0
fi

dnf install python3 gcc python3-devel -y &>> LOG_FILE
VALIDATE $? "Instaling Python"

id roboshop &>>LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating System User"
else
    echo "user already exists... $Y SKIPPING $N "
fi

mkdir -p /app
VALIDATE $? "Creating app Directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> LOG_FILE
VALIDATE $? "Downloading Packages"

rm -rf /app/*
cd /app 
unzip /tmp/payment.zip &>> LOG_FILE
VALIDATE $? "Unzipping Packages"

cd /app 
pip3 install -r requirements.txt &>> LOG_FILE
VALIDATE $? "Installing Requirements"

cp -p $SCRIPT_PATH/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>> LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable payment &>> LOG_FILE
VALIDATE $? "Enabling payment"
systemctl start payment &>> LOG_FILE
VALIDATE $? "Starting payment"