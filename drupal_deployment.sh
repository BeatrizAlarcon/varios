#/bin/bash

############################################################################
# Drupal-based web apps deployment script                                  #
#                                                                          #
#                                                                          #
#  Author: Álvaro Reig González                                            #
#  Licence: GNU GLPv3                                                      # 
#  www.alvaroreig.com                                                      #
#  https://github.com/alvaroreig                                           #
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

if [ ${#ARGS[*]} -lt 4 ]; then
  echo "Four arguments are needed"
  echo "Usage: bash drupal_deployment.sh [SVN_REPO] [APP_NAME] [USER] [SERVER]"
  exit;
else
	SVN_REPO=${ARGS[0]}
	APP_NAME=${ARGS[1]}
	USER=${ARGS[2]}
	SERVER=${ARGS[3]}

	SSH_PREFIX="ssh "$USER"@"$SERVER
	ROOT_SSH_PREFIX="ssh root@"$SERVER

	echo "SVN_REPO" $SVN_REPO
	echo "APP_NAME" $APP_NAME
	echo "USER" $USER
	echo "SERVER" $SERVER

	echo "SSH_PREFIX" $SSH_PREFIX
	echo "ROOT_SSH_PREFIX" $ROOT_SSH_PREFIX
fi

echo "loggin into remote server"
TMP_DIR_NAME=$TMP_DIR_ROOT$APP_NAME"-"$DATE"-"$TIMESTAMP

PORTAL_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-portal"
RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

echo "Creating temp dir:" $TMP_DIR_NAME
$SSH_PREFIX mkdir $TMP_DIR_NAME
$SSH_PREFIX mkdir $TMP_DIR_NAME"/trunk"
SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
CONFIG_FILES_DIR=$TMP_DIR_NAME"/config"
TMP_SVN_LOG=$TMP_DIR_NAME"/"svn_log.tmp

echo "Downloading code from SVN repository"
$SSH_PREFIX svn co "$SVN_REPO""/trunk" $TMP_DIR_NAME"/trunk" "> $TMP_SVN_LOG"
$SSH_PREFIX svn co "$SVN_REPO""/config" $TMP_DIR_NAME"/config" "> $TMP_SVN_LOG"
REVISION_NUMER=`$SSH_PREFIX "cat $TMP_SVN_LOG |grep obtenida | cut -c21-22"`
echo "Revision number: " $REVISION_NUMER
NEW_RELEASE_DIR=$APP_NAME"-rev"$REVISION_NUMER

echo "The new release will be stored in "$NEW_RELEASE_DIR
##TMP##
NEW_RELEASE_DIR=$APS_DIR_ROOT$APP_NAME"/"$NEW_RELEASE_DIR
##FTMP###

echo "Checking if the last version is already present"
RELEASE_ALREADY_PRESENT=$( $SSH_PREFIX ls -al "$APS_DIR_ROOT$APP_NAME""/" | grep "$NEW_RELEASE_DIR")

if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
	echo "The latest revision is" $REVISION_NUMER "which is already present"
	echo "Deleting temp files"
	$SSH_PREFIX "rm -rf $TMP_DIR_ROOT$APP_NAME*"
	echo "Process aborted."
	exit 0
fi

echo "Creating release directory: " $NEW_RELEASE_DIR
$SSH_PREFIX mkdir $NEW_RELEASE_DIR

echo "Copying code to release directory"
$SSH_PREFIX "cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR">/tmp/copia.log

echo "Copying configuration file (PRE)"
$SSH_PREFIX cp -rv "$CONFIG_FILES_DIR""/config_files/pre/settings.php" "$NEW_RELEASE_DIR""/sites/default/settings.php"

echo "Deleting hidden files in release directory"
$SSH_PREFIX "rm -rf \`find $NEW_RELEASE_DIR/ -name '\.*'\` "

echo "Checking that every hidden file was deleted"
$SSH_PREFIX "find $NEW_RELEASE_DIR/ -name '\.*'"

echo "Deleting temp dir"
$SSH_PREFIX rm -rf $TMP_DIR_NAME

echo "Deleting symlink pointing to the current version"
$SSH_PREFIX rm $PORTAL_DIR

echo "Symlinking the new release"
$SSH_PREFIX ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR

echo "Symlinking the files folder from the resources directory"
$SSH_PREFIX ln -s "$RESOURCE_DIR""/files" "$PORTAL_DIR""/sites/default"

echo "chown to www-data the new release directory and the symlink directory"
$ROOT_SSH_PREFIX "chown -h www-data:"$USER" $PORTAL_DIR ; chmod 774 -R $NEW_RELEASE_DIR ; chown -R www-data:"$USER" $NEW_RELEASE_DIR"

echo "Process completed, deleting temp files"
$SSH_PREFIX "rm -rf $TMP_DIR_ROOT$APP_NAME*"

echo "Done"
exit 0
