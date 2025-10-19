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

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 Failure"
        exit 1
    else    
        echo -e "$2 Success"
    fi
}

dnf module disable nginx -y &>> LOG_FILE
VALIDATE $? "Disabling nginx"
dnf module enable nginx:1.24 -y &>> LOG_FILE
VALIDATE $? "Enabling nginx"
dnf install nginx -y &>> LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>> LOG_FILE
VALIDATE $? "Enabling nginx"
systemctl start nginx &>> LOG_FILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing Old source code"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> LOG_FILE
VALIDATE $? "Downloading source code"

cd /usr/share/nginx/html 
rm -rf /usr/share/nginx/html/* 
unzip /tmp/frontend.zip &>> LOG_FILE
VALIDATE $? "Unzipping frontend files"

cp $SCRIPT_PATH/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "coping nginx.conf file"

systemctl restart nginx &>> LOG_FILE
VALIDATE $? "Restarting nginx"