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

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-org -y &>>LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>LOG_FILE
VALIDATE $? "Enabled MongoDB"

systemctl start mongod
VALIDATE $? "Started MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections to MongoDB"

systemctl restart mongod
VALIDATE $? "Restarted MongoDB"