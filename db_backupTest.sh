#!/bin/bash

echo ":-------------------------- DB 백업을 시작 합니다. ---------------------------------:"

#백업 디렉토리
now_dir="/root/bin"
backup_dir="/root/backup/testTemp"

#테스트 개발 db 접속 정보 1
db1_user="user_mocahdev"
db1_password="user_mocahdev_11"
db1_host="192.168.0.100"
db1_port="3306"
db1_name="mocah_db"
#제외 테이블 
except_table1="BULK_COUPON_MST"
except_table2="MMS_LOG"
except_table3="COUPON_STUS_CHNG_HIST"
except_table4="EMARTICON_USE_CNCL"
except_table5="CIS_OFFLINE_COUPON_INFO"

## db 추가시 : --databases db1, db2 


#테스트 개발 db 접속 정보 2
db2_user="cnt89"
db2_password="smj@36298"
db2_host="203.245.44.84"
db2_port="3306"

#db1백업 파일명 
db1_backup_file="mocah_$(date +%Y%m%d).sql"
db2_backup_file="mocah_uplus_$(date +%Y%m%d).sql"

#S3 버킷 이름과 업로드할 폴더 경로 
bucket_name="mocah-backup"
s3_folder="db/prod"

#백업 명령어 실행 
echo ":--------------------------- 1. DB1 백업 정보 확인 ---------------------------------------:"
echo ":---------------- user -> $db1_user , host -> $db1_host, port -> $db1_port ---------------:"
mysqldump --routines --triggers -u $db1_user -p$db1_password -h $db1_host -P $db1_port --quick --max_allowed_packet=512M --skip-add-locks --skip-lock-tables  $db1_name --ignore-table=$db1_name.$except_table1 --ignore-table=$db1_name.$except_table2 --ignore-table=$db1_name.$except_table3 --ignore-table=$db1_name.$except_table4 --ignore-table=$db1_name.$except_table5 > $db1_backup_file

#백업 성공 여부 
if [ $? -eq 0 ]; then
	echo "Mysql 데이터 베이스 백업이 성공적으로 완료 되었습니다."
	tar cvzf $db1_backup_file.tar $db1_backup_file
	rm $db1_backup_file

	#압축 파일 이동 
	mv $now_dir/$db1_backup_file.tar $backup_dir

	#s3적재 
	aws s3 cp $backup_dir/$db1_backup_file.tar s3://$bucket_name/$s3_folder/ 
        
 	#s3 업로드 확인
	if [ $? -eq 0 ]; then
		echo "파일이 성공적으로 업로드 되었습니다."
		rm $backup_dir/$db1_backup_file.tar
	else
		echo "파일 업로드에 실패 했습니다."
		cat error.log
	fi
else
	echo "Mysql 데이터 베이스 백업에 실패 하였습니다."

fi 


#백업 명령어 실행 
echo ":--------------------------- 2. DB2 백업 정보 확인 ---------------------------------------:"
echo ":--------------- user -> $db2_user , host -> $db2_host , port -> $db2_port ---------------:"
mysqldump -u $db2_user -p$db2_password -h $db2_host -P $db2_port --skip-add-locks --skip-lock-tables cnt89 > $db2_backup_file
#mysqldump -u cnt89 -P 3306 -psmj@36298 -h 203.245.44.84   --skip-add-locks --skip-lock-tables cnt89 > $db2_backup_file

#백업이 성공 했는지 확인 
if [ $? -eq 0 ]; then 
	echo "Mysql 데이터 베이스 백업이 성공적으로 완료 되었습니다."
	#백업 파일 압축
        tar cvzf  $db2_backup_file.tar $db2_backup_file
      	rm $db2_backup_file 
	
	#압축 파일 이동 
	mv $now_dir/$db2_backup_file.tar $backup_dir

	#s3에 적재
	#aws s3 cp $backup_dir s3://$bucket_name/$s3_folder/ --recursive
	#aws s3 cp $backup_dir/$db2_backup_file.tar s3://$bucket_name/$s3_folder/
       	aws s3 cp  $backup_dir/$db2_backup_file.tar s3://$bucket_name/$s3_folder/$(date +%Y)/$(date +%m)/$(date +%d)/	

	# s3 업로드 확인
        if [ $? -eq 0 ]; then 
		echo "파일이 성공적으로 업로드 되었습니다."
		# 적재 완료 후 , 해당 압축 파일 삭제 
		rm $backup_dir/$db2_backup_file.tar
	else 
		echo "파일 업로드에 실패 했습니다."
		cat error.log
	fi

else 
	echo "Mysql 데이터 베이스 백업에 실패 하셨습니다. "
fi


