#!/bin/bash

############################################################################
# OCR recursive script. It uses google's "tesseract-ocr" and Geza Kovacs's #
# pdfocr util to recurse into a directory and perform OCR on PDFs          #
#                                                                          #
#  tesseract: https://code.google.com/p/tesseract-ocr/                     #
#  pdfocr: https://github.com/gkovacs/pdfocr                               #
#                                                                          #
# recursive_ocr.sh SOURCE_DIRECTORY                                        #
#                                                                          #
#                                                                          #
#  Author: Álvaro Reig González                                            #
#  Licence: GNU GLPv3                                                      #
#  www.alvaroreig.com                                                      #
#  https://github.com/alvaroreig                                           #
#                                                                          #
# ToDo                                                                     #
# -Exclussion management: based on size, keywords, etc.                    #
# -Adjust timeout based on file size                                       #
############################################################################

DATE=`date +%Y%m%d`
TIMESTAMP=$(date +%m%d%y%H%M%S)
DATE_MARK=`date +%Y-%m-%d_%R`
LOG_MARK="["$DATE_MARK"]"
SUFIX="-before-ocr-"$DATE-$TIMESTAMP
FILETYPE="pdf"
PDFOCR="ruby /opt/pdfocr/pdfocr.rb -t"
TIMEOUT_LIMIT="10m"
LOG=/opt/pdfocr/ocr.log
DATE_TMP=`date +%Y%m%d`
DELETE_TMP_FILES="rm -rf /tmp/d"$DATE_TMP"*"
EMPTY_FONTS_HEADER_SIZE=153

FILES_ALREADY_PROCESSED=0
FILES_PROCESSED=0
FILES_ATTEMPTED=0
FILES_ALREADY_SEARCHABLE=0
FILES_TOTAL=0

DRY_RUN=false

ARGS=("$@")
if [ ${#ARGS[*]} -ne 1 ]; then
  echo "Incorrect number of arguments, expected a single argument"
  echo "Usage: bash recursive_ocr.sh SOURCE_DIRECTORY"
  exit;
fi


echo $LOG_MARK ""  >> $LOG
echo $LOG_MARK "============================"  >> $LOG
echo $LOG_MARK "==Starting recursive OCR===="  >> $LOG
echo $LOG_MARK "============================"  >> $LOG

recurse() {
  for i in "$1"/*;do
    if [ -d "$i" ];then
        recurse "$i"
    elif [ -f "$i" ]; then
      echo $LOG_MARK "============="  >> $LOG
        echo $LOG_MARK "File:" "$i" >> $LOG
        
        filename=$(basename "$i")
        dirname=$(dirname "$i")
        extension="${filename##*.}"
        file="${filename%.*}"

        echo $LOG_MARK "filename:" $filename  >> $LOG

        if [ $extension == $FILETYPE ]; then
           echo $LOG_MARK "Found "$FILETYPE" type" >> $LOG
           let FILES_TOTAL=$FILES_TOTAL+1

           #Check that the file wasn't already processed
           PROCESS_FILE=true
           cd "$dirname"
           for a in `ls "$file"*`; do
            if [[ "$a" == *ocr* ]]; then
              echo $LOG_MARK "This file was already processed"  >> $LOG
              let FILES_ALREADY_PROCESSED=$FILES_ALREADY_PROCESSED+1
              PROCESS_FILE=false
              break
            fi
          done

          # Check that the file is not searchable 
          FONTS=`pdffonts "$filename"`
          if [[ ${#FONTS} -ne $EMPTY_FONTS_HEADER_SIZE ]]; then
            echo $LOG_MARK "This file has fonts, assuming that it is already searchable"  >> $LOG
            if [[ $PROCESS_FILE == true ]]; then
              PROCESS_FILE=false
              let FILES_ALREADY_SEARCHABLE=$FILES_ALREADY_SEARCHABLE+1
            fi
          fi

          if [[ $PROCESS_FILE == true ]]; then

            #Running tesseract
            echo $LOG_MARK "--------------"  >> $LOG
            let FILES_ATTEMPTED=$FILES_ATTEMPTED+1
            new_name=$file$SUFIX"."$extension

            if [[ $DRY_RUN == false ]]; then
              timeout $TIMEOUT_LIMIT $PDFOCR -i "$filename" -o "$new_name"  >> $LOG
            fi
          

            #If tesseract succeded, swap the files
            if [[ -f $new_name ]]; then
              echo $LOG_MARK "swapping files"  >> $LOG
              mv "$new_name" temp
              mv "$filename" "$new_name"
              mv temp "$filename"
              echo "--------------"  >> $LOG
              echo $LOG_MARK "Original file moved to" "$new_name"  >> $LOG
              echo $LOG_MARK "Processed file moved to" "$filename"  >> $LOG

              let FILES_PROCESSED=$FILES_PROCESSED+1
            fi
          fi

          # Tesseract stores temp files in /tmp, if they are not
          # deleted we will run out of free space
          $DELETE_TMP_FILES
        fi
    fi
 done
}

recurse "$1"

echo ""
echo ""
echo $LOG_MARK "============================" >> $LOG
echo $LOG_MARK "=   FINAL REPORT           =" >> $LOG
echo $LOG_MARK "============================" >> $LOG
echo $LOG_MARK "Dry run flag was set to:" $DRY_RUN >> $LOG
echo $LOG_MARK "Total files in directory:" $FILES_TOTAL >> $LOG
echo $LOG_MARK "Files ignored because they were already processed:" $FILES_ALREADY_PROCESSED >> $LOG
echo $LOG_MARK "Files ignored because they were already searchable:" $FILES_ALREADY_SEARCHABLE >> $LOG
echo $LOG_MARK "Files attempted:" $FILES_ATTEMPTED >> $LOG
echo $LOG_MARK "Files processed:" $FILES_PROCESSED >> $LOG
echo $LOG_MARK "Elapsed time:" $SECONDS "seconds." >> $LOG

