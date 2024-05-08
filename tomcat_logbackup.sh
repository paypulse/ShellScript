#!/bin/bash
CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME : ----------------------------: [시작] 레거시 톰캣 로그 쌓기"

#현재 년/월
YEAR=$(date +%Y --date="2 day ago")
MONTH=$(date +%m --date="2 day ago")
DAYS=$(date +%d --date="2 day ago")

DATE_DIR=$YEAR"/"$MONTH
FILE_NAME="common.log."$YEAR"-"$MONTH"-"$DAYS

#### 환경 [ENV_CUR] : local, dev, prod
################################ LOCAL #########################################
ENV_CUR="local"
DIR_S3_PATH="s3://mocah-backup/logs/legacy/$ENV_CUR"


### 아래 정보 들은 배열로 가지고 있을 필요가 있음 
PATH1="/root/common-logs/api-tomcat-7.0.2/logs/admin"
PATH2="/root/common-logs/mos_apache-tomcat-7.0.99/logs/admin"
PATH3="/root/common-logs/mos_batch_apache-tomcat-7.0.99/logs/admin"

PRO_NAME1="api"
PRO_NAME2="mos"
PRO_NAME3="mos-batch"

LIST_FILE_ARR=(1 2 3)
################################## PROD #################################
## prod 환경 : 61, 63, 64
## mos , mos-batch - 64 번  
# ENV_CUR="prod"
# DIR_S3_PATH="s3://mocah-backup/logs/legacy/$ENV_CUR"
# PRO_NAME1="mos"
# PRO_NAME2="mos_batch"
# PATH1="/home/mocah/apache-tomcat-7.0.99/logs/admin"
# PATH2="/home/mocah/mos_batch_apache-tomcat-7.0.99/logs/admin"
# LIST_FILE_ARR=(1 2)

## api - 63번
# PRO_NAME1="api"
# PATH1="/home/mocah/apache-tomcat-7.0.2_new/logs/admin"
# LIST_FILE_ARR=(1)

## Uplus - 61번
# PRO_NAME1="uplus"
# PATH1="/home/mocah/UPLUS_apache-tomcat-7.0.2/logs/admin"
# LIST_FILE_ARR=(1)

#################################### DEV ###################################
## dev 환경  :  150 
# ENV_CUR="dev"
# DIR_S3_PATH="s3://mocah-backup/logs/legacy/$ENV_CUR"

# PRO_NAME1="mos"
# PRO_NAME2="mos_batch"
# PRO_NAME3="api"
# PRO_NAME4="uplus"

# PATH1="/home/mocah/mos_apache-tomcat-7.0.99/logs/admin"
# PATH2="/home/mocah/mos_batch_apache-tomcat-7.0.99/logs/admin"
# PATH3="/home/mocah/api-tomcat-7.0.2/logs/admin"
# PATH4="/home/mocah/uplus_apache-tomcat-7.0.99/logs/admin"

##########################################################################

# s3에 key path로 보내기 
for i in ${LIST_FILE_ARR[@]}; do
    
    #파일 존재 유무
    name=$(eval echo \$$"PRO_NAME"$i)
    path=$(eval echo \$$"PATH"$i)

    path+="/"$FILE_NAME
    echo $path

    CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
    if [ -f "$path" ]; then     
        echo "$CURRENT_DATETIME :  exist  upload 시작 ---------------------------------" 

        #aws s3 cp $path  $DIR_S3_PATH"/"$name"/"$DATE_DIR"/"

        if [ $? -eq 0 ]; then 
            echo "$CURRENT_DATETIME : ------------------파일이 성공적으로 업로드 되었습니다.-------------- "
        else 
            echo "$CURRENT_DATETIME : ------------------파일 업로드가 실패 했습니다. -------------- "
        fi
    else
        echo "$CURRENT_DATETIME :  해당 파일이 없습니다. --------------------------------" 
    fi
 
    
done


CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME :  ----------------------------: [종료] 레거시 톰캣 로그 쌓기"


