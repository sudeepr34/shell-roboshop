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
SCRIPT_PATH=/home/ec2-user/shell-roboshop/
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


dnf install mysql-server -y
VALIDATE $? "INstalling MySQL"
systemctl enable mysqld
VALIDATE $? "Enabling MySQL"
systemctl start mysqld  
VALIDATE $? "Starting MySQL"

mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "Password has been set"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Secong $N"