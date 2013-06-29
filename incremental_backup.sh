#!/bin/bash

############################################################################
# Simple backup script. It uses complete and incremental backups, with     #
# hard links to simulate snapshots. $FULL_BACKUP_LIMIT controls the        #
# frecuency of full backups.It accepts at least one source directory and a #
# single destination directory as arguments. Usage:                        #
#                                                                          #
# incremental_backup.sh SOURCE_DIRECTORY_1 [SOURCE_DIRECTORY_2..N]  			 #
#       DESTINATION_DIRECTORY                                              #
#                                                                          #
#  Todo:                                                                   #
# - Delete old backups                                                     #
# - Better exclusion management                                            #
# - Simulation flag                                                        #
############################################################################

DATE=`date +%Y%m%d` 
TIMESTAMP=$(date +%m%d%y%H%M%S) 
FULL_BACKUP_STRING=backup-full-$DATE-$TIMESTAMP
INC_BACKUP_STRING=backup-inc-$DATE-$TIMESTAMP
FULL_BACKUP_LIMIT=6
LOG=/var/log/backup.log

echo ""
echo ""
echo "[" `date +%Y-%m-%d_%R` "]" "###### Starting backup #######" >> $LOG


############################################################################
# Arguments processing. The last argument is the destination directory, the#
# previous arguments are the source[s] directory[ies]                      #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 2 ]; then
  echo "At least two arguments are needed" >> $LOG
  echo "Usage: bash incremental_backup [SOURCE_DIR_1]...[SOURCE_DIR_N] [DESTINATION_DIR]" >> $LOG
else

  #Store the destination directory
  DEST_DIR=${ARGS[${#ARGS[*]}-1]}

  #Store the first source directory
  SOURCE_DIRS=${ARGS[0]}
  let LAST_SOURCE_POSITION=${#ARGS[*]}-2
  SOURCE_COUNTER=1
  
  #Store the next source directories
  while [ $SOURCE_COUNTER -le $LAST_SOURCE_POSITION ]; do
    CURRENT_SOURCE_DIR=${ARGS[$SOURCE_COUNTER]-1]}
    let SOURCE_COUNTER=SOURCE_COUNTER+1
    SOURCE_DIRS=$SOURCE_DIRS" "$CURRENT_SOURCE_DIR
  done

  echo "Directories to backup" $SOURCE_DIRS >> $LOG
  echo "Destination directory" $DEST_DIR >> $LOG
fi

############################################################################
# Browse previous backups                                                  #
############################################################################
BACKUPS=`ls -t $DEST_DIR |grep backup-`
BACKUP_COUNTER=0
BACKUPS_LIST=()

for x in $BACKUPS
do
    BACKUPS_LIST[$BACKUP_COUNTER]="$x"
    echo "[" `date +%Y-%m-%d_%R` "]" "backup detected:" ${BACKUPS_LIST[$BACKUP_COUNTER]} >> $LOG
    let BACKUP_COUNTER=BACKUP_COUNTER+1 
    
done

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
	rsync -h -ab --stats --exclude '.cache/' --exclude '.thumbnails/' --exclude '.gvfs' --delete $SOURCE_DIRS $DEST_DIR/$FULL_BACKUP_STRING >> $LOG
else
	echo "[" `date +%Y-%m-%d_%R` "]" "The next backup will be incremental" >> $LOG
	rsync -h -ab --stats --exclude '.cache/' --exclude '.thumbnails/' --exclude '.gvfs' --delete --link-dest=$DEST_DIR/$LAST_FULL_BACKUP $SOURCE_DIRS $DEST_DIR/$INC_BACKUP_STRING >> $LOG
fi

############################################################################
# Log the backup status                                                    #
############################################################################

STATUS=$?
if [ $? -ne 0 ]; then
	echo "[" `date +%Y-%m-%d_%R` "]" "####### Error during the backup. Please execute the script with the -v flag #######" >> $LOG
  echo ""
  echo ""
else
	echo "[" `date +%Y-%m-%d_%R` "]" "####### Backup correct #######" >> $LOG
  echo ""
  echo ""
fi
