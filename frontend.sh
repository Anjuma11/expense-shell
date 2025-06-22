USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/expense-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

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
        echo "$2 is............ $G SUCCESS $W" |tee -a $LOG_FILE
    else
        echo "$2 is............ $R FAILURE $W" |tee -a $LOG_FILE
        exit 1
    fi
}

dnf install nginx -y   &>>$LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx   
systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "Enabling and Starting nginx" 

rm -rf /usr/share/nginx/html/*   &>>$LOG_FILE
VALIDATE $? "Removing default HTML" 

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE
VALIDATE $? "downloading frontend" 

cd /usr/share/nginx/html
unzip /tmp/frontend.zip   &>> $LOG_FILE
VALIDATE $? "unzipping frontend"

cp $SCRIPT_DIR/expense.conf /etc/nginx/default.d/expense.conf  &>>$LOG_FILE
VALIDATE $? "Copying expense conf"

systemctl restart nginx   &>>$LOG_FILE
VALIDATE $? "Restarting nginx"
