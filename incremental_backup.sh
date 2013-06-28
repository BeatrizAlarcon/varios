#!/bin/bash

############################################################################
# Simple backup script. It uses complete and incremental backups, with     #
# hard links to simulate snapshots. It accepts two source directories #
# as arguments. Usage:                                                     #
#                                                                          #
# incremental_backup.sh SOURCE_DIRECTORY_1 OURCE_DIRECTORY_2							 #
#                                                                          #
#  Todo:                                                                   #
# - Better input arguments management                                      #
# - Logging                                                                #
# - Delete old backups                                                     #
# - Better exclusion management                                            #
############################################################################

SOURCE_DIR=$1" "$2
DEST_DIR=/media/400gb/backup/rsync
DATE=`date +%Y%m%d` 
TIMESTAMP=$(date +%m%d%y%H%M%S) 
FULL_BACKUP_STRING=backup-full-$DATE-$TIMESTAMP
INC_BACKUP_STRING=backup-inc-$DATE-$TIMESTAMP
FULL_BACKUP_LIMIT=6
LOG=/var/log/backup.log




echo "[" `date +%Y-%m-%d_%R` "]" "###### Starting backup #######" >> /var/log/backup.log
############################################################################
# Browse previous backups                                                  #
############################################################################
BACKUPS=`ls -t $DEST_DIR |grep backup-`
BACKUP_COUNTER=0
BACKUPS_LIST=()

for x in $BACKUPS
do
    BACKUPS_LIST[$BACKUP_COUNTER]="$x"
    #echo "[" `date +%Y-%m-%d_%R` "]" "backup detected:" ${BACKUPS_LIST[$BACKUP_COUNTER]}
    echo "[" `date +%Y-%m-%d_%R` "]" "backup detected:" ${BACKUPS_LIST[$BACKUP_COUNTER]} >> $LOG
    let BACKUP_COUNTER=BACKUP_COUNTER+1 
    
done

#echo "[" `date +%Y-%m-%d_%R` "]" "Number of previous backups: " ${#BACKUPS_LIST[*]}
echo "[" `date +%Y-%m-%d_%R` "]" "Number of previous backups: " ${#BACKUPS_LIST[*]} >> $LOG


############################################################################
# The next backup will be complete if there is no full backup in the last  #
# FULL_BACKUP_LIMIT backups. If it is incremental, the last full backup    #
# will be used as a reference for the "--link-dest" option                 #
############################################################################

NEXT_BACKUP_FULL=true
COUNTER=0
LAST_FULL_BACKUP=

while [[ $COUNTER -lt $FULL_BACKUP_LIMIT && $COUNTER -lt ${#BACKUPS_LIST[*]} ]]; do
  if [[ ${BACKUPS_LIST[$COUNTER]} == *full* ]]; then
  	NEXT_BACKUP_FULL=false;
  	LAST_FULL_BACKUP=${BACKUPS_LIST[$COUNTER]}
  	break;
  fi
  let COUNTER=COUNTER+1
done

############################################################################
# Finally, the backup is performed                                         #
############################################################################

if [ $NEXT_BACKUP_FULL == true ]; then
	echo "[" `date +%Y-%m-%d_%R` "]" "The next backup will be full" >> $LOG
	rsync -h -ab --stats --exclude '.cache/' --exclude '.thumbnails/' --exclude '.gvfs' --delete $SOURCE_DIR $DEST_DIR/$FULL_BACKUP_STRING >> $LOG
else
	echo "[" `date +%Y-%m-%d_%R` "]" "The next backup will be incremental" >> $LOG
	rsync -h -ab --stats --exclude '.cache/' --exclude '.thumbnails/' --exclude '.gvfs' --delete --link-dest=$DEST_DIR/$LAST_FULL_BACKUP $SOURCE_DIR $DEST_DIR/$INC_BACKUP_STRING >> $LOG
fi

############################################################################
# Log the backup status                                                    #
############################################################################

STATUS=$?
if [ $? -ne 0 ]; then
	echo "[" `date +%Y-%m-%d_%R` "]" "####### Error during the backup. Please execute the script with the -v flag #######" >> $LOG
else
	echo "[" `date +%Y-%m-%d_%R` "]" "####### Backup correct #######" >> $LOG
fi
