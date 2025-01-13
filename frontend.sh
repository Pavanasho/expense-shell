#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP-log"

VALIDATE (){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
    else 
        echo -e "$2 ... $G SUCCESS $N"
    fi        
}

mkdir -p /var/log/expense-logs

echo "Script starts executing at: $TIMESTAMP " &>> $LOG_FILE_NAME

CHECK_ROOT () {
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: you must have sudo access to execute this script"
       exit 1
    fi   
}

CHECK_ROOT

dnf install nginx -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing nginx"

systemctl enable nginx &>> $LOG_FILE_NAME
VALIDATE $? "Enabling nginx"

systemctl start nginx &>> $LOG_FILE_NAME
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/*  &>> $LOG_FILE_NAME
VALIDATE $? "Removing the default data"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $LOG_FILE_NAME
VALIDATE $? "Download the file"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip &>> $LOG_FILE_NAME
VALIDATE $? "Unzipping frontend file"

cp /home/ec2-user/expense-shell/expense.conf /etc/nginx/default.d/expense.conf


systemctl restart nginx &>> $LOG_FILE_NAME
VALIDATE $? "Restart nginx"

