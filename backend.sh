#!/bin/bash

USERID=$(id -u)

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE () {
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

dnf module disable nodejs -y &>> $LOG_FILE_NAME
VALIDATE $? "Disabling default nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE_NAME
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

useradd expense &>> $LOG_FILE_NAME
VALIDATE $? "adding expense user"

mkdir /app &>> $LOG_FILE_NAME
VALIDATE $? "app directory creation"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $LOG_FILE_NAME
VALIDATE $? "app download"

cd /app

unzip /tmp/backend.zip &>> $LOG_FILE_NAME
VALIDATE $? "unzipping the downloaded"

npm install &>> $LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

systemctl daemon-reload &>> $LOG_FILE_NAME
VALIDATE $? "Daemon-reload"

systemctl start backend &>> $LOG_FILE_NAME
VALIDATE $? "Starting backend"

systemctl enable backend &>> $LOG_FILE_NAME
VALIDATE $? "Enabling backend"

dnf install mysql -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing mysql clint"

mysql -h mysql.dpak.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>> $LOG_FILE_NAME
VALIDATE $? "Loading the mysql schema"

systemctl restart backend &>> $LOG_FILE_NAME
VALIDATE $? "Restarting backend"



