#!/bin/bash

R="\e[31m"
G="\e[32m"
y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=172.31.22.68
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


dnf module disable redis -y &>>LOG_FILE
VALIDATE $? "Disabling redis"
dnf module enable redis:7 -y &>>LOG_FILE
VALIDATE $? "Enabling redis"

dnf install redis -y &>>LOG_FILE
VALIDATE $? "Installing redis"


sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf # -e is used to make multiple changes
VALIDATE $? "changing redis conf"

systemctl enable redis &>>LOG_FILE
VALIDATE $? "Enabling redis"
systemctl start redis &>>LOG_FILE
VALIDATE $? "Starting redis"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $Start_TIME))
echo -e "Script executed in: $Y $TOTAL_TIME Secong $N"