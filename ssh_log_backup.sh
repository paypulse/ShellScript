#!/bin/bash
CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME :----------------------------: [시작] 레거시 톰캣 로그 S3 쌓기"


#INI파일 읽어 오기 
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG_FILE=${CURRENT_PATH}/log_backup_conf.ini

#ini 파일 읽기  
SECTION_NAME=("REMOTE1")
LOCAL_MAKE_DIR=${CURRENT_PATH}/log_backup/


#현재 년/월/일/시간 
YEAR=$(date +%Y --date="2 day ago")
MONTH=$(date +%m --date="2 day ago")
DAYS=$(date +%d --date="2 day ago")

DATE_DIR=$YEAR"/"$MONTH
DIR_S3_PATH=$(awk '/^\[BACKUPDIR]/{f=1} f==1&&/^DIR_S3_PATH/{print $3;exit}' ${CONFIG_FILE})/



for sn in "${SECTION_NAME[@]}"; do
   env=$(awk '/^\['$sn']/{f=1} f==1&&/^ENV/{print $3;exit}' ${CONFIG_FILE})
   count=$(awk '/^\['$sn']/{f=1} f==1&&/^SERVICE_COUNT/{print $3;exit}' ${CONFIG_FILE})
   host=$(awk '/^\['$sn']/{f=1} f==1&&/^HOST/{print $3;exit}' ${CONFIG_FILE}) 
   port=$(awk '/^\['$sn']/{f=1} f==1&&/^PORT/{print $3;exit}' ${CONFIG_FILE})
   username=$(awk '/^\['$sn']/{f=1} f==1&&/^USER_NAME/{print $3;exit}' ${CONFIG_FILE})
   
   
   for idx in $(seq 1 $count); do 
        s_name=$(awk '/^\['$sn']/{f=1} f==1&&/^SERVICE_NAME'${idx}'/{print $3;exit}' ${CONFIG_FILE})
        log_path=$(awk '/^\['$sn']/{f=1} f==1&&/^LOG_PATH'${idx}'/{print $3;exit}' ${CONFIG_FILE})
        log_path+=".$YEAR"-"$MONTH"-"$DAYS"
       

        local_path=$LOCAL_MAKE_DIR
        s3_path=$DIR_S3_PATH

        #파일을 다운 받아서 가져올 경로 
        local_path+=$env"/"$s_name
    
        s3_path+=$env"/"$s_name"/"$DATE_DIR"/"

        mkdir -p $local_path
        cd $local_path

       echo "check --- path :::" $log_path"*"
        CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
        echo "$CURRENT_DATETIME : $host : $s_name --------------------:파일을 가져 오기 "
        
        #scp로 해당 파일 가져 오기
        scp -i ~/.ssh/id_rsa -P $port $username@$host:$log_path"*"  $local_path

        
        #파일 여부 : 0 이면 성공 그렇지 않으면 가져오지 않음 
        CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
        if [ $? -eq 0 ]; then
            filename=$(basename "$log_path")
            current_path=$local_path
            local_path+="/"$filename

            #해당 폴더내 파일 갯수 
            count=$(find $current_path  -type f | wc -l)
            echo "$CURRENT_DATETIME : $host :  파일 개수: $count"

            #파일 존재 유무 
            if [ $count -gt 0 ]; then
                echo "file name : " $filename *
                tar -cf  $filename.tar "./"$filename*
            fi
            
            #s3에 해당 디렉토리로 보내기
            #aws s3 cp $local_path".tar" $s3_path --only-show-errors
            CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
            if [ $? -eq 0 ]; then
                echo "$CURRENT_DATETIME : $host :----- s3 upload  : $s_name 업로드 완료 "
               # rm -rf $LOCAL_MAKE_DIR
            else
                echo "$CURRENT_DATETIME : $host :----- s3 upload  : $s_name 업로드 실패 "
            fi
        else 
                echo "$CURRENT_DATETIME : $host : no  $s_name "
        fi 
   done 
done 

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME :----------------------------: [종료] 레거시 톰캣 로그 S3 쌓기"










