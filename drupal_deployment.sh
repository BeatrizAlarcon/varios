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

LOG=/var/log/deployment.log


############################################################################
# Arguments processing.													   #
############################################################################

ARGS=("$@")

if [ ${#ARGS[*]} -lt 4 ]; then
  echo "Four arguments are needed" >> $LOG
  echo "Usage: bash drupal_deployment.sh [SVN_REPO] [APP_NAME] [SSH_PREFIX] [ROOT_SSH_PREFIX]" >> $LOG
  exit;
