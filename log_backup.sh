#!/bin/bash

# 현재 IP 주소 가져오기
CURRNET_IP=""
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG_FILE=${CURRENT_PATH}/log_backup.ini

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME : $CURRNET_IP :----------------------------: [시작] 레거시 톰캣 로그 S3 쌓기"


#### 환경 설정 파일 
ENV_CUR=$(awk '/^\[ENV]/{f=1} f==1&&/^ENV/{print $3;exit}' ${CONFIG_FILE})
#현재 년/월
YEAR=$(date +%Y --date="2 day ago")
MONTH=$(date +%m --date="2 day ago")
DAYS=$(date +%d --date="2 day ago")


DATE_DIR=$YEAR"/"$MONTH
FILE_NAME="common.log."$YEAR"-"$MONTH"-"$DAYS
DIR_S3_PATH=$(awk '/^\[BACKUPDIR]/{f=1} f==1&&/^DIR_S3_PATH/{print $3;exit}' ${CONFIG_FILE})/${ENV_CUR}

PRO_NAME_ARR=()
PATH_ARR=()

#IP 색션 안의 내용
print_section=false
while IFS= read -r line; do
  # 섹션 시작 확인
    if [[ "$line" =~ ^\[$CURRNET_IP\]$ ]]; then
        print_section=true
        continue
    fi

    # 섹션 끝 확인
    if [[ "$line" =~ ^\[.*\]$ ]]; then
        print_section=false
    fi

    # 출력할 섹션인 경우 라인 출력
    if [ "$print_section" = true ]; then
        # 키-값 쌍 추출 (예시: key=value)
        if [[ "$line" =~ ^([^\#][^\=]+)=(.*)$ ]]; then
            PRO_NAME_ARR+=("${BASH_REMATCH[1]}")
            PATH_ARR+=("${BASH_REMATCH[2]}")
        fi
     fi
done < "$CONFIG_FILE"


for i in ${!PRO_NAME_ARR[@]}; do
    path=${PATH_ARR[$i]}"/"$FILE_NAME
    name=${PRO_NAME_ARR[$i]}
    s3_path=$DIR_S3_PATH"/"$name"/"$DATE_DIR"/"

    #s3_path에 공백 제거 
    s3_path=$(echo "$s3_path" | tr -d ' ')
 
   
    CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
    # #파일의 존재 유무 
    if [ -f $path ]; then  
         echo "$CURRENT_DATETIME : $CURRNET_IP : $name 관련 $FILE_NAME 존재 합니다. upload 시작 " 
         #aws s3 cp $path  $s3_path
    else
         echo "$CURRENT_DATETIME : $CURRNET_IP : $name 관련 $FILE_NAME 파일이 없습니다. " 
    fi

done 

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME : $CURRNET_IP :----------------------------: [종료] 레거시 톰캣 로그 S3 쌓기"


