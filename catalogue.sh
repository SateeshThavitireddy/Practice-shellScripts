#!/bin/bash

USERID=$(id -u)
R="\e[31m]"
G="\e[32m]"
Y="\e[33m]"
N="\e[0m]"

LOGS_FOLDER="/var/log/shellscript"
SCRIPT_NAME="$(echo $0 | cut -d "." -f1 )"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST="mongodb.cloncurry.fun"
FILES_DIRECTORY=$(PWD)
mkdir -p $LOGS_FOLDER
echo -e "$G Starting the script execution $N" | tee -a $LOG_FILE

if [ $USERID -ne 0 ];  then
    echo -e "$R you should  execute this script as root user $N" | tee -a $LOG_FILE
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G  $2 is Completed Successfully $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling Nodejs module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nodejs 20 module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
else
    echo -e "$Y roboshop user already exists $N" | tee -a $LOG_FILE
fi
VALIDATE $? "Adding roboshop user"

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating application directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue application code"

cd /app
VALIDATE $? "Changing to application directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning old application code"
unzip /tmp/catalogue.zip
VALIDATE $? "Extracting catalogue application code"

cd /app 

npm install &>>$LOG_FILE
VALIDATE $? "Installing nodejs dependencies"

cp FILES_DIRECTORY/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue systemd service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling catalogue service"
systemctl start catalogue   &>>$LOG_FILE
VALIDATE $? "Starting catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongodb repo file"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing Mongodb client"

mongosh --host MONGODB_HOST </app/db/master-data.js
VALIDATE $? "Loading catalogue schema to Mongodb"

mongosh --host MONGODB_HOST --eval "use catalogue; db.products.findOne()"
VALIDATE $? "Validating catalogue schema load"