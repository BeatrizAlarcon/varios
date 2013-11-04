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
#                                                                          #
# @todo                                                                    #
# - relative symlinks
# - Find out SVN revision before downloading code
# - deploymento to pre/pro environment
#		- input version number
#		- svn tag after deployment
############################################################################

LOG=/tmp/deployment.log
DATE=`date +%Y%m%d` 
TIMESTAMP=$(date +%m%d%y%H%M%S) 
TMP_DIR_ROOT="/tmp/"
APS_DIR_ROOT="/opt/"


############################################################################
# Arguments processing.													   												 #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 2 ]; then
  echo "Two arguments are needed"
  echo "Usage: bash drupal_deployment.sh [SVN_REPO] [APP_NAME]"
  exit;
else
	SVN_REPO=${ARGS[0]}
	APP_NAME=${ARGS[1]}


	echo "SVN_REPO" $SVN_REPO
	echo "APP_NAME" $APP_NAME
fi

TMP_DIR_NAME=$TMP_DIR_ROOT$APP_NAME"-"$DATE"-"$TIMESTAMP

PORTAL_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-portal"
RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

echo "Creating temp dir:" $TMP_DIR_NAME
mkdir $TMP_DIR_NAME
mkdir $TMP_DIR_NAME"/trunk"
SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
CONFIG_FILES_DIR=$TMP_DIR_NAME"/config/"
TMP_SVN_LOG=$TMP_DIR_ROOT"/svn_log.tmp"

echo "Downloading code from SVN repository"
svn co "$SVN_REPO""/trunk" $TMP_DIR_NAME"/trunk" > "$TMP_SVN_LOG"
svn co "$SVN_REPO""/config" $TMP_DIR_NAME"/config" > "$TMP_SVN_LOG"
REVISION_NUMER=`cat $TMP_SVN_LOG |grep obtenida | cut -c21-22`
echo "Revision number: " $REVISION_NUMER
NEW_RELEASE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-rev"$REVISION_NUMER
echo "The new release will be stored in "$NEW_RELEASE_DIR


echo "Checking if the last version is already present"
RELEASE_ALREADY_PRESENT=`ls -al $APS_DIR_ROOT$APP_NAME | grep $NEW_RELEASE_DIR`

if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
	echo "The latest revision is" $REVISION_NUMER "which is already present"
	echo "Deleting temp files"
	rm -rf $TMP_DIR_NAME
	echo "Process aborted."
	exit 0
fi

echo "The latest revision is not present. Creating release directory: " $NEW_RELEASE_DIR
mkdir $NEW_RELEASE_DIR

echo "Copying code to release directory"
cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR  > /dev/null
 
echo "Copying configuration file (PRE)"
cp -rv "$CONFIG_FILES_DIR""/config_files/pre/settings.php" "$NEW_RELEASE_DIR""/sites/default/settings.php" > /dev/null

echo "Deleting hidden files in release directory"
rm -rf `find $NEW_RELEASE_DIR/ -name '\.*'`

echo "Checking that every hidden file was deleted"
find $NEW_RELEASE_DIR/ -name '\.*'

echo "Deleting temp dir"
rm -rf $TMP_DIR_NAME

echo "Deleting symlink pointing to the current version"
rm $PORTAL_DIR

echo "Symlinking the new release"
ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR

echo "Symlinking the files folder from the resources directory"
ln -s "$RESOURCE_DIR""/files" "$PORTAL_DIR""/sites/default"

echo "chown to www-data the new release directory and the symlink directory"
chown -h www-data:$USER $PORTAL_DIR
chmod 774 -R $NEW_RELEASE_DIR
chown -R www-data:$USER $NEW_RELEASE_DIR

echo "Process completed, deleting temp files"
rm -rf $TMP_DIR_NAME

echo "Done"
exit 0
