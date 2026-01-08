#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shellscript"
SCRIPT_NAME="$(echo $0 | cut -d "." -f1 )"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo -e "$R Starting the script execution $N" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R you cannot execute this script as root user $N" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 failed $N" | tee -a $LOG_FILE
        exit 1
    else 
        echo -e "$G $2 is completed successfully $N" | tee -a $LOG_FILE
    fi
}
cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongodb repo file"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing Mongodb"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling Mongodb service"

systemctl start mongod  &>>$LOG_FILE
VALIDATE $? "Starting Mongodb service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf  &>>$LOG_FILE
VALIDATE $? "Updating Mongodb bind IP"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting Mongodb service"