#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shellscript"
SCRIPT_NAME="$(echo $0 | cut -d "." -f1 )"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIRECTORY=$PWD

mkdir -p $LOGS_FOLDER
echo -e "$G Starting User Setup... $N" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run as root or use sudo. $N" | tee -a $LOG_FILE
    exit 1
fi

ALREADY_INSTALLED(){
    dnf module list $?
    if [ $1 -ne 0 ]; then
        echo -e "$Y $2 is not installed. Ready to install. $N" | tee -a $LOG_FILE
        dnf install $2 -y
        VALIDATE $? $2
    else
        echo -e "$G $2 is already installed. $N" | tee -a $LOG_FILE
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R Failed to install $2. Check the log file at $LOG_FILE for details. $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G Successfully installed $2. $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default Node.js module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Node.js 20 module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Node.js"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "$G roboshop user already exists. $N" | tee -
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user application code"

cd /app &>>$LOG_FILE
VALIDATE $? "Changing to /app directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning /app directory"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Extracting user application code"

cd /app 
npm install &>>$LOG_FILE
VALIDATE $? "Installing Node.js dependencies for user application"

cp $SCRIPT_DIRECTORY/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "Copying user systemd service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enabling user service"

systemctl start user &>>$LOG_FILE
VALIDATE $? "Starting user service"