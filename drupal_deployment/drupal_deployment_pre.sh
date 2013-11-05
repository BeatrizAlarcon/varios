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
# - delete old versions
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

if [ ${#ARGS[*]} -lt 4 ]; then
  echo "$LOG_MARK Four arguments are needed"
  echo "$LOG_MARK Usage: bash drupal_deployment.sh [SVN_REPO] [APP_NAME] [OPERATION_USER] [THEME_FILE]"
  exit;
else
	SVN_REPO=${ARGS[0]}
	APP_NAME=${ARGS[1]}
	OPERATION_USER=${ARGS[2]}
	THEME_LINE=${ARGS[3]}

	echo "$LOG_MARK Starting $APP_NAME automatic deployment"

	echo "$LOG_MARK SVN_REPO" $SVN_REPO
	echo "$LOG_MARK APP_NAME" $APP_NAME
	echo "$LOG_MARK OPERATION_USER" $OPERATION_USER
	echo "$LOG_MARK THEME_LINE" $THEME_LINE
fi

TMP_DIR_NAME=$TMP_DIR_ROOT$APP_NAME"-"$DATE"-"$TIMESTAMP

PORTAL_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-portal"
RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

echo "$LOG_MARK Browsing repository revision number"
REVISION_NUMER=`svn info $SVN_REPO |grep $REVISION_KEYWORD: |cut -c12-13`
echo "$LOG_MARK Revision number: " $REVISION_NUMER

NEW_RELEASE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-rev"$REVISION_NUMER

echo "$LOG_MARK Checking if the last version is already present"
RELEASE_ALREADY_PRESENT=`ls -al $APS_DIR_ROOT$APP_NAME | grep $NEW_RELEASE_DIR`


if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
	echo "$LOG_MARK The latest revision is" $REVISION_NUMER "which is already present"
	echo "Process aborted."
	exit 0
fi



echo "$LOG_MARK The latest revision is not present."

echo "$LOG_MARK Creating temp dir: $TMP_DIR_NAME"
mkdir $TMP_DIR_NAME
mkdir $TMP_DIR_NAME"/trunk"
SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
CONFIG_FILES_DIR=$TMP_DIR_NAME"/config/"
TMP_SVN_LOG=$TMP_DIR_ROOT"/svn_log.tmp"

echo "Creating release directory: $NEW_RELEASE_DIR"
mkdir $NEW_RELEASE_DIR

echo "$LOG_MARK Downloading code from SVN repository"
svn co "$SVN_REPO""/trunk" $TMP_DIR_NAME"/trunk" > "$TMP_SVN_LOG"
svn co "$SVN_REPO""/config" $TMP_DIR_NAME"/config" > "$TMP_SVN_LOG"

echo "$LOG_MARK Copying code to release directory"
cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR  > /dev/null
 
echo "$LOG_MARK Copying configuration file PRE"
cp -rv "$CONFIG_FILES_DIR""/config_files/pre/settings.php" "$NEW_RELEASE_DIR""/sites/default/settings.php" > /dev/null

echo "$LOG_MARK Deleting hidden files in release directory"
rm -rf `find $NEW_RELEASE_DIR/ -name '\.*'`

echo "$LOG_MARK Checking that every hidden file was deleted"
find $NEW_RELEASE_DIR/ -name '\.*'

echo "$LOG_MARK Deleting temp dir"
rm -rf $TMP_DIR_NAME

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

echo "$LOG_MARK Inserting revision line in drupal template footer"
echo "$LOG_MARK Revision $REVISION_NUMER deployed on $LOG_MARK" >> $THEME_LINE

echo "$LOG_MARK Process completed, deleting temp files"
rm -rf $TMP_DIR_NAME

echo "$LOG_MARK Done"
exit 0
