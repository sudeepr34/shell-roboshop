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


VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 Failure"
        exit 1
    else    
        echo -e "$2 Success"
    fi
}

dnf install maven -y &>>LOG_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating System User"
else
    echo "user already exists... $Y SKIPPING $N "
fi

mkdir -p /app 
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>LOG_FILE
VALIDATE $? "Downloading the packages"
cd /app
rm -rf /app/*

unzip /tmp/shipping.zip &>>LOG_FILE
VALIDATE $? "Unziping the packages"

cd /app 
mvn clean package &>>LOG_FILE
VALIDATE $? "cleaning the package"
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving the packages to desired locations"

cp -p $SCRIPT_PATH/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Coping shipping.service package to system directory"

systemctl daemon-reload &>>LOG_FILE
VALIDATE $? "Reloading daemon"

systemctl enable shipping &>>LOG_FILE
VALIDATE $? "Enabling Shipping"
systemctl start shipping &>>LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>>LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>LOG_FILE
VALIDATE $? "Creating Schema"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>LOG_FILE
VALIDATE $? "Installing app-user"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>LOG_FILE
VALIDATE $? "Installing master data"

systemctl restart shipping &>>LOG_FILE
VALIDATE $? "Restarting shipping"