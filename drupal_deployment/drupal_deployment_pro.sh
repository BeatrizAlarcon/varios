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
# - deploymento to pre/pro environment
#		- input version number
#		- svn tag after deployment
############################################################################

DATE=`date +%Y%m%d` 
TIMESTAMP=`date +%y%m%d%H%M%S`
LOG_MARK=`date +%Y-%m-%d_%R`
TMP_DIR_ROOT="/tmp/"
APS_DIR_ROOT="/opt/"
REVISION_KEYWORD="Revisión"


############################################################################
# Arguments processing.													   												 #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 5 ]; then
  echo "Four arguments are needed"
  echo "Usage: bash drupal_deployment.sh [SVN_REPO] [APP_NAME] [USER] [SERVER] [THEME_FILE]"
  exit;
else
	SVN_REPO=${ARGS[0]}
	APP_NAME=${ARGS[1]}
	USER=${ARGS[2]}
	SERVER=${ARGS[3]}
	THEME_LINE=${ARGS[4]}

	SSH_PREFIX="ssh "$USER"@"$SERVER
	ROOT_SSH_PREFIX="ssh root@"$SERVER

	echo "SVN_REPO" $SVN_REPO
	echo "APP_NAME" $APP_NAME
	echo "USER" $USER
	echo "SERVER" $SERVER
	echo "THEME_LINE" $THEME_LINE

	echo "SSH_PREFIX" $SSH_PREFIX
	echo "ROOT_SSH_PREFIX" $ROOT_SSH_PREFIX
fi


TMP_DIR_NAME=$TMP_DIR_ROOT$APP_NAME"-"$DATE"-"$TIMESTAMP
PORTAL_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-portal"
RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

echo "$LOG_MARK Browsing repository revision number"
REVISION_NUMER=`svn info $SVN_REPO |grep $REVISION_KEYWORD: |cut -c12-13`
echo "$LOG_MARK Revision number: " $REVISION_NUMER

echo "$LOG_MARK Checking if the last version is already present"
RELEASE_ALREADY_PRESENT=$( $SSH_PREFIX "ls -al $APS_DIR_ROOT$APP_NAME | grep" "rev$REVISION_NUMER")

# if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
# 	echo "$LOG_MARK The latest revision is" $REVISION_NUMER "which is already present"
# 	echo "$LOG_MARK Process aborted."
# 	exit 0
# fi

echo "$LOG_MARK Please insert the full version name, as in app_name-1.3.1-some-fixes-rev69"
read -p "name: "
VERSION_NAME=$REPLY
echo "The version name is: $VERSION_NAME"

if [ "$VERSION_NAME" != *REVISION_NUMER*  ]; then
	echo "$LOG_MARK It seems that the revision number doesn't match the latest revision in the repository."
	echo "$LOG_MARK Please insert the revision number that you want to deploy"
	read -p "Revision number: "
	REVISION_NUMER=$REPLY
fi


# echo "Creating temp dir:" $TMP_DIR_NAME
# $SSH_PREFIX mkdir $TMP_DIR_NAME
# $SSH_PREFIX mkdir $TMP_DIR_NAME"/trunk"
# SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
# CONFIG_FILES_DIR=$TMP_DIR_NAME"/config"
# TMP_SVN_LOG=$TMP_DIR_NAME"/"svn_log.tmp

# echo "Downloading code from SVN repository"
# $SSH_PREFIX svn co "$SVN_REPO""/trunk" $TMP_DIR_NAME"/trunk" "> $TMP_SVN_LOG"
# $SSH_PREFIX svn co "$SVN_REPO""/config" $TMP_DIR_NAME"/config" "> $TMP_SVN_LOG"
# REVISION_NUMER=`$SSH_PREFIX "cat $TMP_SVN_LOG |grep obtenida | cut -c21-22"`
# echo "Revision number: " $REVISION_NUMER
# NEW_RELEASE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-rev"$REVISION_NUMER
# echo "The new release will be stored in "$NEW_RELEASE_DIR


# echo "Checking if the last version is already present"
# RELEASE_ALREADY_PRESENT=$( $SSH_PREFIX ls -al "$APS_DIR_ROOT$APP_NAME""/" | grep "$NEW_RELEASE_DIR")

# if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
# 	echo "The latest revision is" $REVISION_NUMER "which is already present"
# 	echo "Deleting temp files"
# 	$SSH_PREFIX "rm -rf $TMP_DIR_NAME"
# 	echo "Process aborted."
# 	exit 0
# fi

# echo "Creating release directory: " $NEW_RELEASE_DIR
# $SSH_PREFIX mkdir $NEW_RELEASE_DIR

# echo "Copying code to release directory"
# $SSH_PREFIX "cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR">/tmp/copia.log

# echo "Copying configuration file (PRE)"
# $SSH_PREFIX cp -rv "$CONFIG_FILES_DIR""/config_files/pre/settings.php" "$NEW_RELEASE_DIR""/sites/default/settings.php"

# echo "Deleting hidden files in release directory"
# $SSH_PREFIX "rm -rf \`find $NEW_RELEASE_DIR/ -name '\.*'\` "

# echo "Checking that every hidden file was deleted"
# $SSH_PREFIX "find $NEW_RELEASE_DIR/ -name '\.*'"

# echo "Deleting temp dir"
# $SSH_PREFIX rm -rf $TMP_DIR_NAME

# echo "Deleting symlink pointing to the current version"
# $SSH_PREFIX rm $PORTAL_DIR

# echo "Symlinking the new release"
# $SSH_PREFIX ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR

# echo "Symlinking the files folder from the resources directory"
# $SSH_PREFIX ln -s "$RESOURCE_DIR""/files" "$PORTAL_DIR""/sites/default"

# echo "chown to www-data the new release directory and the symlink directory"
# $ROOT_SSH_PREFIX "chown -h www-data:"$USER" $PORTAL_DIR ; chmod 774 -R $NEW_RELEASE_DIR ; chown -R www-data:"$USER" $NEW_RELEASE_DIR"

# echo "Process completed, deleting temp files"
# $SSH_PREFIX "rm -rf $TMP_DIR_NAME"

# echo "Done"
# exit 0
