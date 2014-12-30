#/bin/bash

############################################################################
# Moodle deployment script                                  #
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
############################################################################

DATE=`date +%Y%m%d` 
TIMESTAMP=`date +%y%m%d%H%M%S`
LOG_MARK=`date +%Y-%m-%d_%R`
DIRECTORY_MARK=`date +%Y-%m-%d`
TMP_DIR_ROOT="/tmp/"
APS_DIR_ROOT="/opt/"
DATA_DIR="/data/moodle-resource/25/"
SIMON_DATA_DIR="/data/simon-resource/datos/logotipos/"
REVISION_KEYWORD="Revisión:"
NUMBER_OF_VERSIONS_TO_KEEP="5"
MOODLE_HEADER="moodle_"
MOODLE_GIT_REPOSITORY_NAME="moodle"



 # Function to find out if a string contains a substring
  strindex() { 
    x="${1%%$2*}"
    [[ $x = $1 ]] && echo -1 || echo ${#x}
  }



############################################################################
# Arguments processing.													   												 #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 5 ]; then
  echo "$LOG_MARK Four arguments are needed"
  echo "$LOG_MARK Usage: bash moodle_deployment.sh [http://user:password@GITREPO] [MOODLE_VERSION] [OPERATION_USER] [pre/pro] [THEME_FILE]"
  exit;
else
	REPO=${ARGS[0]}
	MOODLE_VERSION=${ARGS[1]}
	OPERATION_USER=${ARGS[2]}
  ENVIRONMENT=${ARGS[3]}
  THEME_FILE=${ARGS[4]}

	echo "$LOG_MARK ----------------------------------------"
	echo "$LOG_MARK Starting $APP_NAME deployment"

	echo "$LOG_MARK SVN_REPO" REPO
	echo "$LOG_MARK MOODLE_VERSION" $MOODLE_VERSION
	echo "$LOG_MARK OPERATION_USER" $OPERATION_USER
  echo "$LOG_MARK ENVIRONMENT" $ENVIRONMENT
  echo "$LOG_MARK THEME_FILE" $THEME_FILE
fi

TMP_DIR_NAME=$TMP_DIR_ROOT$MOODLE_HEADER$MOODLE_VERSION"-"$DATE"-"$TIMESTAMP

PORTAL_DIR=$APS_DIR_ROOT$MOODLE_HEADER$MOODLE_VERSION
# RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

# Cloning Git Repository
echo "$LOG_MARK Cloning repo"
mkdir "$TMP_DIR_NAME"
cd $TMP_DIR_NAME
git clone $REPO

if [ $? -ne 0 ]; then
  echo "$LOG_MARK Error while connecting to Git Repo, aborting."
  rm -rf $NEW_RELEASE_DIR
  rm -rf $TMP_DIR_NAME
  exit -2
fi

# Find out last GIT commit revision
cd $MOODLE_GIT_REPOSITORY_NAME
GIT_LOG_OUTPUT=`git log -n 1 --pretty=oneline`
GIT_LOG_LAST_COMMIT=`echo $GIT_LOG_OUTPUT | cut -c1-40`
echo "$LOG_MARK Last commit: $GIT_LOG_OUTPUT"

# Check that the root app directory exists
if [ ! -d "$APS_DIR_ROOT" ]; then
  echo "$LOG_MARK The expected directory doesn't exist, aborting."
  echo "$RELEASE_ALREADY_PRESENT"
  rm -rf $NEW_RELEASE_DIR
  rm -rf $TMP_DIR_NAME
  exit -2
fi


# If environment == PRE, the release dir is automatic
if [ "$ENVIRONMENT" == "pre" ]; then

  # Find out if that version is already deployed
  RELEASE_ALREADY_PRESENT=`ls -al $APS_DIR_ROOT | grep $GIT_LOG_LAST_COMMIT`

  if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
    echo "$LOG_MARK The latest commit " $GIT_LOG_LAST_COMMIT "is already deployed"
    echo "Process aborted."
    exit -1
  fi

  echo "$LOG_MARK The latest revision is not deployed."

  # Check if old revisions should be deleted
  echo "$LOG_MARK Checking if old revisions should be deleted"
  DEPLOYED_VERSIONS=`ls -tr $APS_DIR_ROOT |grep $MOODLE_HEADER$MOODLE_VERSION`
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
    echo "$LOG_MARK Need to delete" $VERSIONS_TO_DELETE" versions"
    
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
  NEW_RELEASE_DIR=$APS_DIR_ROOT$MOODLE_HEADER$MOODLE_VERSION"_"$DIRECTORY_MARK"_commit_"$GIT_LOG_LAST_COMMIT
  echo "$NEW_RELEASE_DIR"
  echo "$LOG_MARK Creating release dir $NEW_RELEASE_DIR. Copying files..."
  mkdir $NEW_RELEASE_DIR


elif [ "$ENVIRONMENT" == "PRO" ]; then
  # PRO environment

  # Ask for the deployment version
  echo "$LOG_MARK Please insert the full version name, as in 1.3.1-some-fixes-20141027"
  read -p "name: "
  VERSION_NAME=$REPLY
  VERSION_NAME="$MOODLE_HEADER-$VERSION_NAME"
  echo "The version name is: $VERSION_NAME"

  # Check if that revision is already deployed
  echo "$LOG_MARK Checking if the desired revision is already present"
  RELEASE_ALREADY_PRESENT=`ls -al $APS_DIR_ROOT | grep $VERSION_NAME`
  echo $RELEASE_ALREADY_PRESENT
  if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
    echo "$LOG_MARK The latest revision is" $REVISION_NUMBER "which is already present"
    echo "$LOG_MARK Process aborted."
    exit -2
  fi

  # Creating directories
  echo "$LOG_MARK Creating release dir $NEW_RELEASE_DIR. Copying files..."
  mkdir $NEW_RELEASE_DIR

else
    echo "Invalid ENVIRONMENT specified, must be 'pre' or 'pro'"
    echo "$LOG_MARK Process aborted."
    rm -rf $NEW_RELEASE_DIR
    rm -rf $TMP_DIR_NAME
    exit -2
fi

# Common instructions for pre|pro

# Copying files
cp -rv $TMP_DIR_NAME"/"$MOODLE_GIT_REPOSITORY_NAME"/trunk/"* $NEW_RELEASE_DIR >> /dev/null
cp -rv $TMP_DIR_NAME"/"$MOODLE_GIT_REPOSITORY_NAME"/config/config_files/$ENVIRONMENT/"* $NEW_RELEASE_DIR >> /dev/null
echo "$LOG_MARK End file copy"

# sym link to data directories
echo "$LOG_MARK symlink pointing to the data directory"
ln -s $DATA_DIR $NEW_RELEASE_DIR"/moodle/datos"
ln -s $SIMON_DATA_DIR $NEW_RELEASE_DIR"/login/simon/datos/logotipos"

# point app_symlink to the new version
echo "$LOG_MARK Deleting symlink pointing to the current version"
rm $PORTAL_DIR

echo "$LOG_MARK Symlinking the new release"
ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR




echo $TMP_DIR_NAME
exit -3




# Creating directories
echo "$LOG_MARK Creating temp dir: $TMP_DIR_NAME"
mkdir $TMP_DIR_NAME
mkdir $TMP_DIR_NAME"/trunk"
SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
CONFIG_FILES_DIR=$TMP_DIR_NAME"/config/config_files/pre/"
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

svn co "$SVN_REPO""/config/config_files/pre" $CONFIG_FILES_DIR > "$TMP_SVN_LOG"
if [ $? -ne 0 ]; then
  echo "$LOG_MARK Error while connecting to SVN, aborting."
  rm -rf $NEW_RELEASE_DIR
  rm -rf $TMP_DIR_NAME
  exit -2
fi

# Deleting hidden files
echo "$LOG_MARK Deleting hidden files in sources directory"
rm -rf `find $TMP_DIR_NAME/ -name '\.*'`

# Copying code and setting symlinks
echo "$LOG_MARK Copying code to release directory"
cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR  > /dev/null
 
echo "$LOG_MARK Copying configuration file PRE"
echo $CONFIG_FILES_DIR
echo $NEW_RELEASE_DIR
cp -rv $CONFIG_FILES_DIR* $NEW_RELEASE_DIR"/" > /dev/null


echo "$LOG_MARK Checking that every hidden file was deleted"
find $NEW_RELEASE_DIR/ -name '\.*'

# sym link to data directory
echo "$LOG_MARK symlink pointing to the data directory"
ln -s $DATA_DIR $NEW_RELEASE_DIR"/moodle/datos"
ln -s $SIMON_DATA_DIR $NEW_RELEASE_DIR"/login/simon/datos/logotipos"

# point app_symlink to the new version
echo "$LOG_MARK Deleting symlink pointing to the current version"
rm $PORTAL_DIR

echo "$LOG_MARK Symlinking the new release"
ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR

echo "$LOG_MARK chown to www-data the new release directory and the symlink directory"
chown -h www-data:$OPERATION_USER $PORTAL_DIR
chmod 774 -R $NEW_RELEASE_DIR
chown -R www-data:$OPERATION_USER $NEW_RELEASE_DIR

# Insert mark so the developers can see the revision number
echo "$LOG_MARK Inserting revision line in login page footer"
echo "$LOG_MARK Revision $REVISION_NUMBER deployed on $LOG_MARK" >> $THEME_FILE

echo "$LOG_MARK Process completed, deleting temp files"
rm -rf $TMP_DIR_NAME
service apache2 reload

echo "$LOG_MARK Done"
exit 0

