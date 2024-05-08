#!/bin/bash

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo ":--------------------------$CURRENT_DATETIME  start, clean s3 bucket ---------------------------------:"


#ENV
ENV_CUR="dev"

# 폴더 경로 
FOLDER_PATH="s3://mocah-backup/db/$ENV_CUR"
AWS_DEFAULT_REGION="ap-northeast-2"
AWS_CMD="aws s3 rm"


#이전 월 
MONTH=$(date +%m --date="2 month ago")
#현재 년도
YEAR=$(date +%Y --date="2 month ago")
LAST_MONTH=$YEAR"/"$MONTH

if [ $MONTH -eq 02 ]; then
   
    LAST_MONTH=$YEAR
fi

echo $FOLDER_PATH/$LAST_MONTH

$AWS_CMD $FOLDER_PATH"/"$LAST_MONTH  --recursive --region $AWS_DEFAULT_REGION

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo ":--------------------------$CURRENT_DATETIME end, clean s3 bucket ---------------------------------:"