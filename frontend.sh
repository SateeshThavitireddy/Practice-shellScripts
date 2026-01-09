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
echo -e "$G Starting Frontend Setup... $N" | tee -a $LOG_FILE

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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "nginx module disable" 

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "nginx module"      

dnf install nginx -y    &>>$LOG_FILE
VALIDATE $? "nginx" 

systemctl enable nginx  &>>$LOG_FILE
VALIDATE $? "nginx enable"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "nginx start"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Download Frontend Artifact"

cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "Change Directory to Nginx HTML Folder"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Clean Nginx HTML Folder"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Extract Frontend Artifact"

cp $SCRIPT_DIRECTORY/nginx.conf /etc/nginx/nginx.conf    &>>$LOG_FILE
VALIDATE $? "Copy Nginx Configuration"

systemctl restart nginx &>>$LOG_FILE        
VALIDATE $? "Restart Nginx Service"