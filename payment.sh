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

dnf install python3 gcc python3-devel -y | tee -a $LOG_FILE
VALIDATE $? "Python3 and GCC"

id roboshop &>> $LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "roboshop user creation"
else
    echo -e "$G roboshop user already exists. $N" | tee -
fi 

mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Create /app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "Download payment component"

cd /app 

rm -rf /app/* &>> $LOG_FILE
VALIDATE $? "Clean /app directory"

unzip /tmp/payment.zip &>> $LOG_FILE
VALIDATE $? "Extract payment component"

cd /app 
pip3 install -r requirements.txt &>> $LOG_FILE
VALIDATE $? "Install Python dependencies"

cp $SCRIPT_DIRECTORY/payment.service /etc/systemd/system/payment.service &>> $LOG_FILE
VALIDATE $? "Copy payment systemd service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Reload systemd"

systemctl enable payment &>> $LOG_FILE
VALIDATE $? "Enable payment service"

systemctl start payment &>> $LOG_FILE
VALIDATE $? "Start payment service"

echo -e "$G payment Setup Completed Successfully. $N" | tee -a $LOG_FILE