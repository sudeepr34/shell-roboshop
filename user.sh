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
SCRIPT_PATH=$(PWD)
START_TIME=$(date +%s)


mkdir -p $LOGS_FOLDER
echo "script started execution at: $(date)"

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

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "Disabling nodejs"
dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enabling nodejs"
dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "created user roboshop"
mkdir -p /app 
VALIDATE $? "created /app directory"

rm -rf /app/*
VALIDATE $? "Removing Existing code"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "downloaded binaries"
cd /app 
unzip /tmp/user.zip
VALIDATE $? "unzipping the contents"

cd /app 
npm install 
VALIDATE $? "install npm"

cp -p $SCRIPT_PATH/user.service /etc/systemd/system/user.service

systemctl daemon-reload
VALIDATE $? "Reloading Daemon"

systemctl enable user 
VALIDATE $? "Enabling User"

systemctl start user
VALIDATE $? "Starting User"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"