#!/bin/bash

#### 설정 파일 경로 
## 현재 경로 
CURRENT_PATH=$(pwd)
CONFIG_FILE=${CURRENT_PATH}/config.ini

#### DIR 경로 지정 
#DB 환경 
ENV_CUR=$(awk '/^\[ENV]/{f=1} f==1&&/^ENV/{print $3;exit}' ${CONFIG_FILE})
DIR_BACKUP_PATH=~/db_backup
DIR_DATE=$(date +%Y%m%d)
DIR_S3_PATH=$(awk '/^\[BACKUPDIR]/{f=1} f==1&&/^DIR_S3_PATH/{print $3;exit}' ${CONFIG_FILE})/${ENV_CUR}/$(date +%Y)/$(date +%m)/$(date +%d)

## BACK UP DIRECTORY 생성 후 이동
if [[ -d "$DIR_BACKUP_PATH" ]]; then 
   echo "directory exit"
   cd $DIR_BACKUP_PATH
else
   echo "directory does not exist"
   mkdir -p  $DIR_BACKUP_PATH
   cd $DIR_BACKUP_PATH
fi 

#### ini 파일을 읽어 와서 처리 
# 섹션 이름이 들어갈 배열 생성
DB_SECTIONS=()

#Dump 된 파일 저장 
DB_DUMP_FILE=()

#섹션 갯수 
while IFS= read -r line; do 
   if [[ "$line" == "[DB"* ]]; then 
	DB_SECTIONS+=("$line")
	continue
   fi 

done < "$CONFIG_FILE"

for i in ${DB_SECTIONS[@]}; do

   #Host,port,user_name, db_name 
   DB_HOST=$(awk '/^\'$i'/{f=1} f==1&&/^HOST/{print $3;exit}' ${CONFIG_FILE}) 
   DB_PORT=$(awk '/^\'$i'/{f=1} f==1&&/^PORT/{print $3;exit}' ${CONFIG_FILE})
   DB_USER=$(awk '/^\'$i'/{f=1} f==1&&/^USER/{print $3;exit}' ${CONFIG_FILE})
   DB_PASS=$(awk '/^\'$i'/{f=1} f==1&&/^PASSWORD/{print $3;exit}' ${CONFIG_FILE})

   DB_NAME1=$(awk '/^\'$i'/{f=1} f==1&&/^NAME1/{print $3;exit}' ${CONFIG_FILE})
   DB_NAME2=$(awk '/^\'$i'/{f=1} f==1&&/^NAME2/{print $3;exit}' ${CONFIG_FILE})
    
   ##### 백업 DB 파일명 #######
   DB_FILE=$(awk '/^\'$i'/{f=1} f==1&&/^FILE/{print $3;exit}' ${CONFIG_FILE})$DIR_DATE.sql
    
   echo "=================== start.db.backup.$i.$DB_FILE"

   ### 환경에 따라 변경  : prod는 ignore없지만, dev는 ignore존재 
   if [[ "$ENV_CUR" == "dev" ]]; then 

      ###ignore table 존재 
      DB_IGN1=$(awk '/^\[EXCEPTTABLES]/{f=1} f==1&&/^DB_EXCEPT1/{print $3;exit}' ${CONFIG_FILE})  
      DB_IGN2=$(awk '/^\[EXCEPTTABLES]/{f=1} f==1&&/^DB_EXCEPT2/{print $3;exit}' ${CONFIG_FILE})  
      DB_IGN3=$(awk '/^\[EXCEPTTABLES]/{f=1} f==1&&/^DB_EXCEPT3/{print $3;exit}' ${CONFIG_FILE})  
      DB_IGN4=$(awk '/^\[EXCEPTTABLES]/{f=1} f==1&&/^DB_EXCEPT4/{print $3;exit}' ${CONFIG_FILE})  
      DB_IGN5=$(awk '/^\[EXCEPTTABLES]/{f=1} f==1&&/^DB_EXCEPT5/{print $3;exit}' ${CONFIG_FILE})  

      mysqldump --routines --triggers -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT --skip-add-locks --skip-lock-tables --databases $DB_NAME1 $DB_NAME2  --ignore-table=$DB_NAME1.$DB_IGN1   --ignore-table=$DB_NAME1.$DB_IGN2   --ignore-table=$DB_NAME1.$DB_IGN3  --ignore-table=$DB_NAME1.$DB_IGN4  --ignore-table=$DB_NAME1.$DB_IGN5 > $DB_FILE
      #파일 생성 여부 
      if [[ -f "$DB_FILE" ]]; then 
         filesize=$(wc -c "$DB_FILE" | awk '{print $1}')
         if [ $filesize -lt 1 ]; then
            echo "check.file.size.$i.$DB_FILE.$filesize"
         else
            echo "complete.dump.file.$i.$DB_FILE.$filesize"
         fi
         echo $filesize "덤프 파일 생성" 
      else 
         echo $filesize "덤프 파일 미 생성"
      fi

      DB_DUMP_FILE+=("$DB_FILE")

   else
      echo "prod mode"
      mysqldump --routines --triggers -u$DB_USER -p$DB_PASS -h$DB_HOST -P$DB_PORT --skip-add-locks --skip-lock-tables --databases $DB_NAME1  $DB_NAME2 > $DB_FILE
      #파일 생성 여부 
      if [[ -f "$DB_FILE" ]]; then 
         filesize=$(wc -c "$DB_FILE" | awk '{print $1}')
         if [ $filesize -lt 1 ]; then
            echo "check.file.size.$i.$DB_FILE.$filesize"
         else
            echo "complete.dump.file.$i.$DB_FILE.$filesize"
         fi
            echo $filesize "덤프 파일 생성" 
      else 
            echo $filesize "덤프 파일 미 생성"
      fi
      DB_DUMP_FILE+=("$DB_FILE")
   fi

done

for i in ${DB_DUMP_FILE[@]}; do 

   if [[ -f "$i" ]]; then 
      aws s3 cp ./$i $DIR_S3_PATH
      rm -rf $i
   fi
done 

echo ":----------------------------------- DB 백업을 종료 합니다. ---------------------------------------------------------------------------:"








