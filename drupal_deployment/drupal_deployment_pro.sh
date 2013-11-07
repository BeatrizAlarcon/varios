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
#			-1: incorrect Arguments 																						 #
#     -2: current revision already deployed                                #
#     -3: error while connecting to svn                                    #
#                                                                          #
# @todo                   																								 #
# - relative symlinks																											 #
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
  echo "Four arguments are needed"
  echo "Usage: bash drupal_deployment.sh [SVN_REPO] [APP_NAME] [USER] [SERVER]"
  exit -1;
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


TMP_DIR_NAME=$TMP_DIR_ROOT$APP_NAME"-"$DATE"-"$TIMESTAMP
PORTAL_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-portal"
RESOURCE_DIR=$APS_DIR_ROOT$APP_NAME"/"$APP_NAME"-resource"

echo "$LOG_MARK Please insert the redmine issue number associated to this deployment without '#', as in 4587"
read -p "Issue number: "
REDMINE_ISSUE_NUMBER=$REPLY
if [[ $REDMINE_ISSUE_NUMBER == *[!0-9]* ]]; then
	echo "$LOG_MARK Inorrect issue format"
	exit -1
fi

echo "$LOG_MARK Browsing repository revision number"
REVISION_NUMER=$($SSH_PREFIX svn info $SVN_REPO |grep $REVISION_KEYWORD: |cut -c12-13)
if [ -z "$REVISION_NUMER" ]; then
  echo "$LOG_MARK Error while connecting to SVN, aborting."
  $SSH_PREFIX "rm -rf $TMP_DIR_NAME"
  exit -3
fi
echo "$LOG_MARK Revision number:" $REVISION_NUMER

echo "$LOG_MARK Please insert the full version name, as in app_name-1.3.1-some-fixes-rev$REVISION_NUMER"
read -p "name: "
VERSION_NAME=$REPLY
echo "The version name is: $VERSION_NAME"

# Checking if the version name is in the expected form: app_name-varios-messages-rev70
if [[ "$VERSION_NAME" != "$APP_NAME-"* ]] || [[ "$VERSION_NAME" != *"-rev"* ]] ; then
	echo "Incorrect version name"
	exit -1
fi

# Check if revision to be deployed is not the latest one
if [[ "$VERSION_NAME" != *rev$REVISION_NUMER* ]]; then
	echo "$LOG_MARK It seems that the revision number doesn't match the latest revision in the repository."
	echo "$LOG_MARK Please insert the revision number that you want to deploy"
	read -p "Revision number: "
	REVISION_NUMER_INPUT=$REPLY

	if [[ $REVISION_NUMER_INPUT == *[!0-9]* ]]; then
    echo "$LOG_MARK Incorrect revision format, aborting"
    exit -1
	fi

	if [[ $REVISION_NUMER_INPUT > $REVISION_NUMER ]]; then
		echo "$LOG_MARK Revision greater than the last one, aborting"
		exit -1
	fi

	# Adjusting the desired revision number
	REVISION_NUMER=$REVISION_NUMER_INPUT
	echo "$LOG_MARK New revision number:" $REVISION_NUMER
fi

echo "$LOG_MARK Checking if the desired revision is already present"
RELEASE_ALREADY_PRESENT=$( $SSH_PREFIX "ls -al $APS_DIR_ROOT$APP_NAME | grep" "rev$REVISION_NUMER")

if [ "$RELEASE_ALREADY_PRESENT" != "" ]; then
	echo "$LOG_MARK The latest revision is" $REVISION_NUMER "which is already present"
	echo "$LOG_MARK Process aborted."
	exit -2
fi

echo "$LOG_MARK Creating temp dir:" $TMP_DIR_NAME
$SSH_PREFIX mkdir $TMP_DIR_NAME
$SSH_PREFIX mkdir $TMP_DIR_NAME"/trunk"
SOURCES_DIR=$TMP_DIR_NAME"/trunk/"
CONFIG_FILES_DIR=$TMP_DIR_NAME"/config"
TMP_SVN_LOG=$TMP_DIR_NAME"/"svn_log.tmp

echo "$LOG_MARK Downloading code from SVN repository"

$SSH_PREFIX svn co "$SVN_REPO""/trunk@$REVISION_NUMER" $TMP_DIR_NAME"/trunk" "> $TMP_SVN_LOG"

$SSH_PREFIX svn co "$SVN_REPO""/config@$REVISION_NUMER" $TMP_DIR_NAME"/config" "> $TMP_SVN_LOG"

NEW_RELEASE_DIR=$APS_DIR_ROOT$APP_NAME"/$VERSION_NAME"
echo "$LOG_MARK The new release will be stored in "$NEW_RELEASE_DIR


echo "$LOG_MARK Creating release directory: " $NEW_RELEASE_DIR
$SSH_PREFIX mkdir $NEW_RELEASE_DIR

echo "$LOG_MARK Copying code to release directory"
$SSH_PREFIX "cp -rv $SOURCES_DIR* $NEW_RELEASE_DIR">/tmp/copia.log

echo "$LOG_MARK Copying configuration file (PRO)"
$SSH_PREFIX cp -rv "$CONFIG_FILES_DIR""/config_files/pro/settings.php" "$NEW_RELEASE_DIR""/sites/default/settings.php"

echo "$LOG_MARK Deleting hidden files in release directory"
$SSH_PREFIX "rm -rf \`find $NEW_RELEASE_DIR/ -name '\.*'\` "

echo "$LOG_MARK Checking that every hidden file was deleted"
$SSH_PREFIX "find $NEW_RELEASE_DIR/ -name '\.*'"

echo "$LOG_MARK Deleting symlink pointing to the current version"
$SSH_PREFIX rm $PORTAL_DIR

echo "$LOG_MARK Symlinking the new release"
$SSH_PREFIX ln -s "$NEW_RELEASE_DIR" $PORTAL_DIR

echo "$LOG_MARK Symlinking the files folder from the resources directory"
$SSH_PREFIX ln -s "$RESOURCE_DIR""/files" "$PORTAL_DIR""/sites/default"

echo "$LOG_MARK chown to www-data the new release directory and the symlink directory"
$ROOT_SSH_PREFIX "chown -h www-data:"$USER" $PORTAL_DIR ; chmod 774 -R $NEW_RELEASE_DIR ; chown -R www-data:"$USER" $NEW_RELEASE_DIR"

echo "$LOG_MARK Performing SVN Tag"
DEPLOYMENT_TAG_MESSAGE="$LOG_MARK Production deployment of version $VERSION_NAME fixes #$REDMINE_ISSUE_NUMBER"
echo "$LOG_MARK $DEPLOYMENT_TAG_MESSAGE"
$SSH_PREFIX svn copy "$SVN_REPO/trunk@$REVISION_NUMER" "$SVN_REPO/tags/$VERSION_NAME -m \"$DEPLOYMENT_TAG_MESSAGE\""

echo "$LOG_MARK Process completed, deleting temp files"
$SSH_PREFIX "rm -rf $TMP_DIR_NAME"

echo "$LOG_MARK Done"
exit 0
