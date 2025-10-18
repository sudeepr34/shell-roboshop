#!/bin/bash

set -euo pipefail

trap 'echo "there is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=172.31.22.68
SCRIPT_PATH=/home/ec2-user/shell-roboshop/


mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)"

USERID=$(id -u)

if [ $USERID -ne 0 ]; then
    echo "ERROR: Please run this script with root access"
    exit 1 # failure is other than 0
fi


VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 Failure"
        exit 1
    else    
        echo -e "$2 Success"
    fi
}

######## NodeJS ############
dnf module disable nodejs -y &>>LOG_FILE

dnf module enable nodejs:20 -y &>>LOG_FILE

dnf install nodejs -y &>>LOG_FILE

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
    echo "user already exists... SKIPPING"
fi

mkdir -p /app 


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_FILE

cd /app

rm -rf /app/*

unzip /tmp/catalogue.zip &>>LOG_FILE

cd /app 
npm install &>>LOG_FILE

cp $SCRIPT_PATH/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload &>>LOG_FILE

systemctl enable catalogue &>>LOG_FILE

systemctl start catalogue &>>LOG_FILE


cp $SCRIPT_PATH/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>LOG_FILE

INDEX=$(mongosh 172.31.22.68 --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -le 0 ]; then
    mongosh --host 172.31.22.68 </app/db/master-data.js
else
    echo -e "Catalogue already exists"
fi

systemctl restart catalogue
