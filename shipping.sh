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
echo -e "$G Starting SHIPPING Setup... $N" | tee -a $LOG_FILE

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Roboshop User"
else 
    echo -e "$G Roboshop user already exists. $N" | tee -a $LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Create Application Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Download Shipping Application"

cd /app &>>$LOG_FILE
VALIDATE $? "Change Directory to /app"
rm -rf * &>>$LOG_FILE
VALIDATE $? "Clean Application Directory"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Extract Shipping Application"

cd /app &>>$LOG_FILE
VALIDATE $? "Change Directory to /app"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Build Shipping Application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Rename Shipping JAR File"

cp $SCRIPT_DIRECTORY/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copy Shipping Systemd Service File"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reload Systemd Daemon"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable Shipping Service"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Start Shipping Service"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Install MySQL Client"

mysql -h mysql.cloncurry.fun -uroot -pRoboShop@1 < /app/db/schema.sql
VALIDATE $? "Load Shipping Schema"
mysql -h mysql.cloncurry.fun -uroot -pRoboShop@1 < /app/db/app-user.sql 
VALIDATE $? "Create Application Database User"
mysql -h mysql.cloncurry.fun -uroot -pRoboShop@1 < /app/db/master-data.sql
VALIDATE $? "Load Master Data"

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restart Shipping Service"