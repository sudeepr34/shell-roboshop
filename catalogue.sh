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
VALIDATE $? "Disabling nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating System User"
else
    echo "user already exists... $Y SKIPPING $N "
fi

mkdir -p /app 
VALIDATE $? "Creating app Directory"


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_FILE
VALIDATE $? "Downloading Catalogue Application"

cd /app
VALIDATE $? "Changing to app Directory"

rm -rf /app/*
VALIDATE $? "Removing Existing code"

unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "Unzipping Catalogue"

cd /app 
npm install &>>LOG_FILE
VALIDATE $? "Instaling dependencies"

cp $SCRIPT_PATH/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying Systemctl services"

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "Reloading Daemon"

systemctl enable catalogue &>>LOG_FILE
VALIDATE $? "Enabling Catalogue"
systemctl start catalogue &>>LOG_FILE
VALIDATE $? "Starting Catalogue"

cp $SCRIPT_PATH/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "Istalling MongoDB CLient"

INDEX=$(mongosh 172.31.22.68 --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -le 0 ]; then
    mongosh --host 172.31.22.68 </app/db/master-data.js
    VALIDATE $? "Loading Catalogue Products"
else
    echo -e "Catalogue already exists"
fi

systemctl restart catalogue
VALIDATE $? "Restarting Catalogues"