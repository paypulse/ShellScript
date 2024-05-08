#!/bin/bash
CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME :----------------------------: [시작] 레거시 톰캣 로그 삭제 "

CURRNET_IP="114.108.165.67"
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG_FILE=${CURRENT_PATH}/log_legacy_clean.ini


# 현재로 부터 2년전 년월일
YEAR=$(date +%Y  --date="2 years ago")
#2년전 오늘로 부터 1달 전 
MONTH=$(date -d "$YEAR -1 month" +%m)


#FILENAME 만들기
FILENAME_LIST=("catalina" 
                "manager"
                "host-manager" 
                "localhost_access_log"
                "access_log"
                "localhost"
                "common.log")
FILE_LIST=()

#파일 경로
CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
SERVICE_COUNT=$(awk '/^\['$CURRNET_IP']/{f=1} f==1&&/^SERVICE_COUNT/{print $3;exit}' ${CONFIG_FILE})
echo "$CURRENT_DATETIME :----------------------------: SERVICE COUNT : $SERVICE_COUNT  , CURRNET_IP : $CURRNET_IP "

for i in $(seq 1 $SERVICE_COUNT); do 
    path=$(awk '/^\['$CURRNET_IP']/{f=1} f==1&&/^SERVICE'${i}'_PATH/{print $3;exit}' ${CONFIG_FILE})    
    for file in "${FILENAME_LIST[@]}"; do 
        #파일 명 만들기
        path+=$file"."$YEAR"-"$MONTH"-*" 
        FILE_LIST+=("$path")
        path=$(awk '/^\['$CURRNET_IP']/{f=1} f==1&&/^SERVICE'${i}'_PATH/{print $3;exit}' ${CONFIG_FILE})
    done
done 


#파일경로와 명 array for문 
for idx in "${FILE_LIST[@]}"; do 
    CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$CURRENT_DATETIME :----------------------------: $idx  "
    count=$(find $idx  -type f | wc -l)
    echo "$CURRENT_DATETIME :----------------------------: FILE COUNT: $count  "

    CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
    #파일 존재 유무 
    if [ $count -gt 0 ]; then 
       # 삭제
       echo "$CURRENT_DATETIME :----------------------------:  DELETE FILE $idx"
       #rm -rf $idx

       count=$(find $idx  -type f | wc -l)
       echo "$CURRENT_DATETIME :----------------------------: Delete complete $idx   : $count "
    else 
        continue
    fi 

done 

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME :----------------------------: [종료] 레거시 톰캣 로그 삭제"


