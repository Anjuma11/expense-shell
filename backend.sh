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
    echo  -e "You are running the script with root access" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$W $2 is............ $G SUCCESS $W" |tee -a $LOG_FILE
    else
        echo -e "$W $2 is............ $R FAILURE $W" |tee -a $LOG_FILE
        exit 1
    fi
}


dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling nodejs" 

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "enabling nodejs" 

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "Installing nodejs" 

#Checking Expense user existence 
id expense &>> $LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "$N Expense user doesn't exist adding.."
    useradd --system --home /app --shell /sbin/nologin --comment "expense user" expense
    VALIDATE $? "Adding expense User" |tee -a $LOG_FILE
else
    echo -e "Expense user is already exists, $Y SKIPPING $N"
fi

mkdir /app &>> $LOG_FILE
VALIDATE $? "Creating Application directory" 

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $LOG_FILE
VALIDATE $? "Downloading backend code"

cd /app
unzip /tmp/backend.zip 
VALIDATE $? "unzipping backend" 

npm install &>> $LOG_FILE
VALIDATE $? "Installing Nodejs Packages" 

cp $SCRIPT_DIR/backend.serive /etc/systemd/system/backend.service
VALIDATE $? "Copying backend service file" 

systemctl daemon-reload
systemctl start backend
systemctl enable backend 
VALIDATE $? "Starting and Enabling backend" 

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p$MYSQL_ROOT_PASSWORD < /app/schema/backend.sql &>> $LOG_FILE
VALIDATE $? "Loading data into mysql" 

systemctl restart backend &>> $LOG_FILE
VALIDATE $? "Restarting backend" 