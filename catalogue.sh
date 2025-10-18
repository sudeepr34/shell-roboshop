#!/bin/bash

R="\e[31m"
G="\e[32m"
y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.daws86s.fun


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

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating System User"

mkdir /app 
VALIDATE $? "Creating app Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>LOG_FILE
VALIDATE $? "Downloading Catalogue Application"

cd /app
VALIDATE $? "Changing to app Directory"
unzip /tmp/catalogue.zip &>>LOG_FILE
VALIDATE $? "Unzipping Catalogue"

cd /app 
npm install &>>LOG_FILE
VALIDATE $? "Instaling dependencies"

cp /home/ec2-user/shell-roboshop/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying Systemctl services"

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "Reloading Daemon"

systemctl enable catalogue &>>LOG_FILE
VALIDATE $? "Enabling Catalogue"
systemctl start catalogue &>>LOG_FILE
VALIDATE $? "Starting Catalogue"

cp /home/ec2-user/shell-roboshop/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Adding Mongo repo"

dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "Istalling MongoDB CLient"

mongosh --host $MONGODB_HOST </app/db/master-data.js
VALIDATE $? "Loading Catalogue Products"

systemctl restart catalogues &>>LOG_FILE
VALIDATE $? "Restarting Catalogues"