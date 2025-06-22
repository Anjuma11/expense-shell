#!/bin/bash
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/expense-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR::Please run the script with root access $N" |tee -a $LOG_FILE
    exit 1
else
    echo "You are running the script with root access" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is............ $G SUCCESS $W" |tee -a $LOG_FILE
    else
        echo -e "$2 is............ $R FAILURE $W" |tee -a $LOG_FILE
        exit 1
    fi
}

echo "Please enter root password to setup mysql"
read -s MYSQL_ROOT_PASSWORD

dnf install mysql-server -y
VALIDATE $? "installing mysql server"

systemctl enable mysqld
systemctl start mysqld
VALIDATE $? "Enabling and Starting mysql"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD 
VALIDATE $? "Setting Root password"



