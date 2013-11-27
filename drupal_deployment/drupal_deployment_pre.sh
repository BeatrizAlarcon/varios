#/bin/bash

############################################################################
# Drupal-based web apps deployment script                                  #
#                                                                          #
#                                                                          #
#  Author: Álvaro Reig González                                            #
#  Licence: GNU GLPv3                                                      # 
#  www.alvaroreig.com                                                      #
#  https://github.com/alvaroreig                                           #
#                                                                          #
#  Return status:                                                          #
#      0: correct                                                          #
#     -1: last revision already deployed                                   #
#     -2: error while connecting to svn                                    #
#                                                                          #
# @todo                                                                    #
# - relative symlinks                                                      #
# - Check errors while connecting to SVN                                   #
############################################################################

DATE=`date +%Y%m%d` 
TIMESTAMP=`date +%y%m%d%H%M%S`
LOG_MARK=`date +%Y-%m-%d_%R`
TMP_DIR_ROOT="/tmp/"
APS_DIR_ROOT="/opt/"
REVISION_KEYWORD="Revisión:"
NUMBER_OF_VERSIONS_TO_KEEP="5"



 # Function to find out if a string contains a substring
  strindex() { 
    x="${1%%$2*}"
    [[ $x = $1 ]] && echo -1 || echo ${#x}
  }


############################################################################
# Arguments processing.                                                    #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 4 ]; then
  echo "$LOG_MARK Four arguments are needed"
  echo "$LOG_MARK Usage: bash drupal_deployment_pre.sh [SVN_REPO] [APP_NAME] [OPERATION_USER] [THEME_FILE]"
  exit;
else
  SVN_REPO=${ARGS[0]}
  APP_NAME=${ARGS[1]}
  OPERATION_USER=${ARGS[2]}
  THEME_LINE=${ARGS[3]}

  echo "$LOG_MARK ----------------------------------------"
  echo "$LOG_MARK Starting $APP_NAME automatic deployment"

  echo "$LOG_MARK SVN_REPO" $SVN_REPO
  echo "$LOG_MARK APP_NAME" $APP_NAME
  echo "$LOG_MARK OPERATION_USER" $OPERATION_USER
  echo "$LOG_MARK THEME_LINE" $THEME_LINE
fi

TMP_DIR_NAME=$TMP_DIR_ROOT$APP_NAME"-"$DATE"-"$TIMESTAMP

PORTAL_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-portal"
RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

# Find out last SVN revision
echo "$LOG_MARK Browsing repository revision number"
REVISION_NUMBER_OUTPUT=`svn info $SVN_REPO | grep "$REVISION_KEYWORD"`

if [ $? -ne 0 ]; then
  echo "$LOG_MARK Error while connecting to SVN, aborting."
  rm -rf $NEW_RELEASE_DIR
  rm -rf $TMP_DIR_NAME
  exit -2
fi

# Processing the info received from SVN
REVISION_NUMBER_OUTPUT_LENGTH=${#REVISION_NUMBER_OUTPUT}
REVISION_NUMBER_START=`strindex "$REVISION_NUMBER_OUTPUT" ":"`
let REVISION_NUMBER_START=$REVISION_NUMBER_START+4
REVISION_NUMBER=`echo $REVISION_NUMBER_OUTPUT | cut -c$REVISION_NUMBER_START-$REVISION_NUMBER_LENGTH`
echo "$LOG_MARK Revision number: " $REVISION_NUMBER

NEW_RELEASE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-rev"$REVISION_NUMBER

# Check if the latest revision is already deployed
echo "$LOG_MARK Checking if the last revision is already present"
RELEASE_ALREADY_PRESENT=`ls -al $APS_DIR_ROOT$APP_NAME | grep $NEW_RELEASE_DIR`


if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
	echo "$LOG_MARK The latest revision is" $REVISION_NUMER "which is already present"
	echo "Process aborted."
	exit -1
fi



echo "$LOG_MARK The latest revision is not present."

# Check if old revisions should be deleted
echo "$LOG_MARK Checking if old revisions should be deleted"
DEPLOYED_VERSIONS=`ls -tr $APS_DIR_ROOT$APP_NAME |grep -rev`
DEPLOYED_VERSIONS_COUNTER=0
DEPLOYED_VERSIONS_LIST=()

# Iterate through deployed versions
for x in $DEPLOYED_VERSIONS
do
    DEPLOYED_VERSIONS_LIST[$DEPLOYED_VERSIONS_COUNTER]="$x"
    # echo "$LOG_MARK" ${DEPLOYED_VERSIONS_LIST[$DEPLOYED_VERSIONS_COUNTER]}
    let DEPLOYED_VERSIONS_COUNTER=DEPLOYED_VERSIONS_COUNTER+1
done

echo "$LOG_MARK Deleting old versions"
echo "$LOG_MARK Number of deployed versions: " ${#DEPLOYED_VERSIONS_LIST[*]}
echo "$LOG_MARK Number of versions to keep:"      $NUMBER_OF_VERSIONS_TO_KEEP

# Delete revisions, if necessary
if [ $NUMBER_OF_VERSIONS_TO_KEEP -lt $DEPLOYED_VERSIONS_COUNTER ]; then
  let VERSIONS_TO_DELETE=$DEPLOYED_VERSIONS_COUNTER-$NUMBER_OF_VERSIONS_TO_KEEP
  echo "$LOG_MARK Need to delete" $VERSIONS_TO_DELETE" backups"
  
  # Delete from n-1 to 0
  let VERSIONS_TO_DELETE=$VERSIONS_TO_DELETE-1
  while [ $VERSIONS_TO_DELETE -ge 0 ]; do
    VERSION=${DEPLOYED_VERSIONS_LIST[$VERSIONS_TO_DELETE]}
    echo "$LOG_MARK Version to delete:" $VERSION
    rm -rf $APS_DIR_ROOT$APP_NAME"/"$VERSION
    if [ $? -ne 0 ]; then
      echo "$LOG_MARK Error while deleting version"
    else
      echo "$LOG_MARK Version correctly deleted"
    fi
    let VERSIONS_TO_DELETE=VERSIONS_TO_DELETE-1
  done
else
  echo "$LOG_MARK No need to delete old versions"
fi

# Creating directories
echo "$LOG_MARK Creating temp dir: $TMP_DIR_NAME"
mkdir $TMP_DIR_NAME
mkdir $TMP_DIR_NAME"/trunk"
SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
CONFIG_FILES_DIR=$TMP_DIR_NAME"/config/"
TMP_SVN_LOG=$TMP_DIR_ROOT"/svn_log.tmp"

echo "Creating release directory: $NEW_RELEASE_DIR"
mkdir $NEW_RELEASE_DIR

# Code download
echo "$LOG_MARK Downloading code from SVN repository"
svn co "$SVN_REPO""/trunk" $TMP_DIR_NAME"/trunk" > "$TMP_SVN_LOG"
if [ $? -ne 0 ]; then
  echo "$LOG_MARK Error while connecting to SVN, aborting."
  rm -rf $NEW_RELEASE_DIR
  rm -rf $TMP_DIR_NAME
  exit -2
fi

svn co "$SVN_REPO""/config" $TMP_DIR_NAME"/config" > "$TMP_SVN_LOG"
if [ $? -ne 0 ]; then
  echo "$LOG_MARK Error while connecting to SVN, aborting."
  rm -rf $NEW_RELEASE_DIR
  rm -rf $TMP_DIR_NAME
  exit -2
fi

# Copying code and setting symlinks
echo "$LOG_MARK Copying code to release directory"
cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR  > /dev/null
 
echo "$LOG_MARK Copying configuration file PRE"
cp -rv "$CONFIG_FILES_DIR""/config_files/pre/settings.php" "$NEW_RELEASE_DIR""/sites/default/settings.php" > /dev/null

echo "$LOG_MARK Deleting hidden files in release directory"
rm -rf `find $NEW_RELEASE_DIR/ -name '\.*'`

echo "$LOG_MARK Checking that every hidden file was deleted"
find $NEW_RELEASE_DIR/ -name '\.*'

# point app_symlink to the new version
echo "$LOG_MARK Deleting symlink pointing to the current version"
rm $PORTAL_DIR

echo "$LOG_MARK Symlinking the new release"
ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR

echo "$LOG_MARK Symlinking the files folder from the resources directory"
ln -s "$RESOURCE_DIR""/files" "$PORTAL_DIR""/sites/default"

echo "$LOG_MARK chown to www-data the new release directory and the symlink directory"
chown -h www-data:$OPERATION_USER $PORTAL_DIR
chmod 774 -R $NEW_RELEASE_DIR
chown -R www-data:$OPERATION_USER $NEW_RELEASE_DIR

# Insert mark so the developers can see the revision number
echo "$LOG_MARK Inserting revision line in drupal template footer"
echo "$LOG_MARK Revision $REVISION_NUMER deployed on $LOG_MARK" >> $THEME_LINE

echo "$LOG_MARK Process completed, deleting temp files"
rm -rf $TMP_DIR_NAME

echo "$LOG_MARK Done"
exit 0
