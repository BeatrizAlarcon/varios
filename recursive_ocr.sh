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
# -Remove annoying error in line 21                                        #
############################################################################

DATE=`date +%Y%m%d`
TIMESTAMP=$(date +%m%d%y%H%M%S)
LOG_MARK="[" `date +%Y-%m-%d_%R` "]"
SUFIX="-before-ocr-"$DATE-$TIMESTAMP
FILETYPE="pdf"
PDFOCR="ruby /opt/pdfocr/pdfocr.rb -t"
TIMEOUT_LIMIT="10m"
LOG=/opt/pdfocr/ocr.log

FILES_IGNORED=0
FILES_PROCESSED=0
FILES_ATTEMPTED=0
FILES_TOTAL=0

DRY_RUN=false

ARGS=("$@")
if [ ${#ARGS[*]} -ne 1 ]; then
  echo "Incorrect number of arguments, expected a single argument"
  echo "Usage: bash recursive_ocr.sh SOURCE_DIRECTORY"
  exit;
fi


echo $LOG_MARK "============================"  >> $LOG
echo $LOG_MARK "==Starting recursive OCR===="  >> $LOG
echo $LOG_MARK "============================"  >> $LOG

recurse() {
  for i in "$1"/*;do
    if [ -d "$i" ];then
        #echo "dir: $i"
        recurse "$i"
    elif [ -f "$i" ]; then
      echo $LOG_MARK "============="  >> $LOG
        echo $LOG_MARK "File:" "$i" >> $LOG
        let FILES_TOTAL=$FILES_TOTAL+1
        
        filename=$(basename "$i")
        dirname=$(dirname "$i")
        extension="${filename##*.}"
        file="${filename%.*}"

        echo $LOG_MARK "filename:" $filename  >> $LOG
        #echo "extension:" $extension  >> $LOG
        #echo "dirname" $dirname  >> $LOG

        if [ $extension == $FILETYPE ]; then
           echo $LOG_MARK "Found "$FILETYPE" type" >> $LOG

           #Check that the file wasn't already processed
           PROCES_FILE=true
           cd "$dirname"
           for a in `ls "$file"*`; do
            if [[ "$a" == *ocr* ]]; then
              echo $LOG_MARK "This file was already processed"  >> $LOG
              let FILES_IGNORED=$FILES_IGNORED+1
              PROCES_FILE=false
              break
            fi
          done

          if [[ $PROCES_FILE == true ]]; then

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
echo $LOG_MARK "Files ignored because they were already processed:" $FILES_IGNORED >> $LOG
echo $LOG_MARK "Files attempted:" $FILES_ATTEMPTED >> $LOG
echo $LOG_MARK "Files processed:" $FILES_PROCESSED >> $LOG
echo $LOG_MARK "Elapsed time:" $SECONDS "seconds." >> $LOG
