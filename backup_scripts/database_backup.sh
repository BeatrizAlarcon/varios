#!/bin/bash

############################################################################
# Simple database backup script. 
#                                                                          #
# database_backup.sh database_host database_name database_user
# 	database_password DESTINATION_DIRECTORY                                #
#                                                                          #
#                                                                          #
#  Author: Álvaro Reig González                                            #
#  Licence: GNU GLPv3                                                      #    
#  www.alvaroreig.com                                                      #
#  https://github.com/alvaroreig                                           #
############################################################################

DATE=`date +%Y%m%d` 
TIMESTAMP=$(date +%m%d%y%H%M%S) 
BACKUP_STRING=backup-$DATE-$TIMESTAMP-
BACKUPS_TO_KEEP=21

############################################################################
# Arguments processing. The last argument is the destination directory, the#
# previous arguments are the source[s] directory[ies]                      #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 5 ]; then
  echo "Five arguments are needed"
  echo "Usage: bash database_backup.sh database_host database_name database_user
    database_password DESTINATION_DIRECTORY"
  exit;
else
	DATABASE_HOST=${ARGS[0]}
	DATABASE_NAME=${ARGS[1]}
	DATABASE_USER=${ARGS[2]}
	DATABASE_PASSWORD=${ARGS[3]}
	DESTINATION_DIRECTORY=${ARGS[4]}

	echo ""
  echo ""
  echo "[" `date +%Y-%m-%d_%R` "]" "###### Starting backup #######"
  echo "[" `date +%Y-%m-%d_%R` "]" "Databse HOST"  $DATABASE_HOST
  echo "[" `date +%Y-%m-%d_%R` "]" "DATABASE_NAME"  $DATABASE_NAME
  echo "[" `date +%Y-%m-%d_%R` "]" "DATABASE_USER:"  $DATABASE_USER
  echo "[" `date +%Y-%m-%d_%R` "]" "DATABASE_PASSWORD:"       "******"
  echo "[" `date +%Y-%m-%d_%R` "]" "DESTINATION_DIRECTORY:"           $DESTINATION_DIRECTORY
fi

############################################################################
# Browse previous backups                                                  #
############################################################################
BACKUPS=`ls -t $DESTINATION_DIRECTORY |grep $DATABASE_NAME`
BACKUP_COUNTER=0
BACKUPS_LIST=()

for x in $BACKUPS
do
    BACKUPS_LIST[$BACKUP_COUNTER]="$x"
    echo "[" `date +%Y-%m-%d_%R` "]" "backup detected:" ${BACKUPS_LIST[$BACKUP_COUNTER]}
    let BACKUP_COUNTER=BACKUP_COUNTER+1 
done

echo "[" `date +%Y-%m-%d_%R` "]" "number of backups detected:" $BACKUP_COUNTER

############################################################################
# Delete old backups, if necessary                                         #
############################################################################

echo "[" `date +%Y-%m-%d_%R` "]" "###### Deleting old backups ######"
echo "[" `date +%Y-%m-%d_%R` "]" "Number of previous backups: " ${#BACKUPS_LIST[*]}
echo "[" `date +%Y-%m-%d_%R` "]" "Backups to keep:"      $BACKUPS_TO_KEEP

###
if [ $BACKUPS_TO_KEEP -lt ${#BACKUPS_LIST[*]} ]; then
  let BACKUPS_TO_DELETE=${#BACKUPS_LIST[*]}-$BACKUPS_TO_KEEP
  echo "[" `date +%Y-%m-%d_%R` "]" "Need to delete" $BACKUPS_TO_DELETE" backups" $BACKUPS_TO_DELETE

  while [ $BACKUPS_TO_DELETE -gt 0 ]; do
    BACKUP=${BACKUPS_LIST[${#BACKUPS_LIST[*]}-1]}
    unset BACKUPS_LIST[${#BACKUPS_LIST[*]}-1]
    echo "[" `date +%Y-%m-%d_%R` "]" "Backup to delete:" $DESTINATION_DIRECTORY"/"$BACKUP
    rm -rf $DESTINATION_DIRECTORY"/"$BACKUP
    if [ $? -ne 0 ]; then
      echo "[" `date +%Y-%m-%d_%R` "]" "####### Error while deleting backup #######"
    else
      echo "[" `date +%Y-%m-%d_%R` "]" "Backup correctly deleted"
    fi
    let BACKUPS_TO_DELETE=BACKUPS_TO_DELETE-1
  done
else
  echo "[" `date +%Y-%m-%d_%R` "]" "No need to delete backups"  
fi

############################################################################
# Performing Backup                                                        #
############################################################################

echo "[" `date +%Y-%m-%d_%R` "]" "###### Starting backup #######"
mysqldump -h $DATABASE_HOST -u $DATABASE_USER -p$DATABASE_PASSWORD $DATABASE_NAME > $DESTINATION_DIRECTORY"/"$BACKUP_STRING$DATABASE_NAME".sql"
echo "[" `date +%Y-%m-%d_%R` "]" "Backup status: " $?
