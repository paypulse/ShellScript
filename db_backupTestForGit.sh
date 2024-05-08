#!/bin/bash


#current log time 
CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo ":--------------------------$CURRENT_DATETIME  DB 백업을 시작 합니다. ---------------------------------:"

ENV_CUR="dev"
#DIR_S3_PATH="s3://mocah-backup/db/$ENV_CUR/$(date +%Y)/$(date +%m)/$(date +%d)/"
DIR_S3_PATH="s3://mocah-backup/db/$ENV_CUR/2024/04/01/"

DIR_BACKUP_PATH=~/db_backup
#DIR_DATE=$(date +%Y%m%d%h)
DIR_DATE=20240401

DB_HOST2="dev-mocah.cvqckcsqs9gn.ap-northeast-2.rds.amazonaws.com"
DB_PORT2="13306"
DB_USER2="mocah"
DB_PASS2="Y*kqWBY^fa3WS"
DB_NAME2="verycon"
DB_FILE2="mocah_uplus_db_$DIR_DATE.sql"

DB_HOST1="dev-mocah.cvqckcsqs9gn.ap-northeast-2.rds.amazonaws.com"
DB_PORT1="13306"
DB_USER1="mocah"
DB_PASS1="Y*kqWBY^fa3WS"
DB_NAME1="verycon"
DB_FILE1="mocah_db_$DIR_DATE.sql"
#LIST_ARR=(1)

##추가시 
LIST_ARR=(1 2)

####slack 관련 setting 
SLACK_DEV_HOOK="https://hooks.slack.com/services/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"
SLACK_PROD_HOOK="https://hooks.slack.com/services/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"
SLACK_BUILD_HOOK="https://hooks.slack.com/services/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"

ERROR_LOG="error.log"
ERROR_MSG=""

mkdir -p $DIR_BACKUP_PATH
cd $DIR_BACKUP_PATH


for i in ${LIST_ARR[@]}; do
	echo ""

	host=$(eval echo \$$"DB_HOST"$i)
	port=$(eval echo \$$"DB_PORT"$i)
	user=$(eval echo \$$"DB_USER"$i)
	pass=$(eval echo \$$"DB_PASS"$i)
	file=$(eval echo \$$"DB_FILE"$i)
	name=$(eval echo \$$"DB_NAME"$i)

	CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
	echo "=================== start.db.backup.$i.$file , $CURRENT_DATETIME"
	mysqldump --routines --triggers -u$user -p$pass -h$host -P$port --skip-add-locks --skip-lock-tables $name > $file 2> $ERROR_LOG

	#### ERROR LOG Message
	if [ -s $ERROR_LOG ]; then 
		while IFS= read -r line; do 
			ERROR_MSG+="$line"$'\n'
		done < "$ERROR_LOG"
		rm $ERROR_LOG
	else 
		CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
		echo "mysql dump successfully : $CURRENT_DATETIME"
		rm $ERROR_LOG
	fi 	

	if [ -e $file ]; then
		filesize=$(wc -c "$file" | awk '{print $1}')
		if [ $filesize -lt 1 ]; then
			#message를 slack에 보내라 .
			CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S") 
			echo "check.file.size.$ERROR_MSG , $CURRENT_DATETIME"
			echo $ERROR_MSG  
			#curl -H "Content-type: application/json; charset=utf-8" --data "{\"text\": \"$ERROR_MSG\" }" -X POST $SLACK_DEV_HOOK
			curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"MySql Dump is failed $CURRENT_DATETIME \"}" $SLACK_DEV_HOOK
		else
			#성공 했을때
			#curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"success \"}" $SLACK_DEV_HOOK
			CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
			echo $ERROR_MSG 
			echo "complete.dump.file.$i.$file.$filesize , $CURRENT_DATETIME"
			echo ""
			echo "======================  log file test =============================================="
	
			tar -czvf $file.tar -C $DIR_BACKUP_PATH .
			rm -rf $file
			aws s3 cp $DIR_BACKUP_PATH/$file.tar  $DIR_S3_PATH 

			#S3 업로드 확인 
			## $? -> 마직막으로 실행된 명령어의 실행 결과 
			  if [ $? -eq 0 ]; then 
				echo "파일이 성공적으로 업로드 되었습니다."
				# 적재 완료 후 , 해당 압축 파일 삭제 
				rm $DIR_BACKUP_PATH/$file.tar
			else 
				curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"S3 업로드에 실패했습니다. $CURRENT_DATETIME \"}" $SLACK_DEV_HOOK
			fi			

		fi
	else
		CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
		echo "faile : faile.dump.$i.$file"
		echo $ERROR_MSG
		#curl -H "Content-type: application/json; charset=utf-8" --data "{\"text\": \"$ERROR_MSG\" }" -X POST $SLACK_DEV_HOOK
		curl -X POST -H 'Content-type: application/json' --data "{\"text\": \"MySql Dump is failed $CURRENT_DATETIME \"}" $SLACK_DEV_HOOK
		
	fi
	CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
	echo "=================== end.db.backup.$i.$file , $CURRENT_DATETIME"

done

CURRENT_DATETIME=$(date "+%Y-%m-%d %H:%M:%S")
echo ":--------------------------$CURRENT_DATETIME,  DB 백업을 종료 합니다. ---------------------------------:"


