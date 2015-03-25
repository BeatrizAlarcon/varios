#/bin/bash
LINUTMINTPACKAGERULESFILE="/usr/lib/linuxmint/mintUpdate/rules"
PACKAGELEVELLIMIT=3
startdelimiterkeyword="PROGRAM: "
enddelimiterkeyword=" INSTALLED: "


strindex() { 
    x="${1%%$2*}"
    [[ $x = $1 ]] && echo -1 || echo ${#x}
  }



#################################################################################
# Fount out packages that should not be upgraded, according to 'the Mint way',  #
# and store them in the array 'ignoredpackages'                                 #
#################################################################################
ignoredpackages=()
mapfile -t packageslist < <(cat $LINUTMINTPACKAGERULESFILE)

for packageline in "${packageslist[@]}"
do
    # Each line is of this form: banshee|*|2||
    #echo "$packageline"
    IFS='|' read -ra parts <<< "$packageline"

    if [ "${parts[2]}" -gt $PACKAGELEVELLIMIT ]; then
        echo "[" `date +%Y-%m-%d_%R` "]" "Package like ${parts[0]} won't be updated"
        ignoredpackages=(${ignoredpackages[@]} "${parts[0]}")
    else
      echo "[" `date +%Y-%m-%d_%R` "]" "Package like ${parts[0]} can be updated"
    fi
done

# Output ignored packages list
for element in "${ignoredpackages[@]}"
do
    # Each line is of this form: PROGRAM: xorg INSTALLED: 1:7.7+1ubuntu8 AVAILABLE: 1:7.7+1ubuntu8.1
    echo "$element"
done

exit 0


#################################################################
# Find packages that could be upgraded                          #
#################################################################
list=$(apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "PROGRAM: $1 INSTALLED: $2 AVAILABLE: $3\n"}')
#echo $list

echo "---"
mapfile -t lines < <(apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "PROGRAM: $1 INSTALLED: $2 AVAILABLE: $3\n"}')

for element in "${lines[@]}"
do
	# Each line is of this form: PROGRAM: xorg INSTALLED: 1:7.7+1ubuntu8 AVAILABLE: 1:7.7+1ubuntu8.1
    echo "$element"
    
    # Remove "PROGRAM: "
    startprogram=$(strindex "$element" "$startdelimiterkeyword")
    let endprogram=startprogram+${#startdelimiterkeyword}+1
    stringsize=${#element}
    element=`echo "$element" | cut -c"$endprogram"-"$stringsize"`
    echo "$element"
    
    #Remove everything after " INSTALLED..."
    startinstalled=$(strindex "$element" "$enddelimiterkeyword")
    echo "$element" | cut -c1-"$startinstalled"

    echo "-----"
done