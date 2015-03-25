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
        #echo "[" `date +%Y-%m-%d_%R` "]" "Package like ${parts[0]} won't be updated"
        ignoredpackages=(${ignoredpackages[@]} "${parts[0]}")
    #else
        #echo "[" `date +%Y-%m-%d_%R` "]" "Package like ${parts[0]} can be updated"
    fi
done

# Output ignored packages list
echo "[" `date +%Y-%m-%d_%R` "]" "List of patterns to ignore:"
for element in "${ignoredpackages[@]}"
do
    # Each line is of this form: PROGRAM: xorg INSTALLED: 1:7.7+1ubuntu8 AVAILABLE: 1:7.7+1ubuntu8.1
    echo "$element"
done

#################################################################
# Find packages that could be upgraded,                         #
# parsing the info from 'apt-get --just-print upgrade'          #
# and filtering the packages in 'ignoredpackages'               #
#################################################################
packagestoupgrade=()
list=$(apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "PROGRAM: $1 INSTALLED: $2 AVAILABLE: $3\n"}')
#echo $list

echo "---"
mapfile -t lines < <(apt-get --just-print upgrade 2>&1 | perl -ne 'if (/Inst\s([\w,\-,\d,\.,~,:,\+]+)\s\[([\w,\-,\d,\.,~,:,\+]+)\]\s\(([\w,\-,\d,\.,~,:,\+]+)\)? /i) {print "PROGRAM: $1 INSTALLED: $2 AVAILABLE: $3\n"}')

for element in "${lines[@]}"
do
	# Each line is of this form: PROGRAM: xorg INSTALLED: 1:7.7+1ubuntu8 AVAILABLE: 1:7.7+1ubuntu8.1
    #echo "$element"
    
    # Remove "PROGRAM: "
    startprogram=$(strindex "$element" "$startdelimiterkeyword")
    let endprogram=startprogram+${#startdelimiterkeyword}+1
    stringsize=${#element}
    element=`echo "$element" | cut -c"$endprogram"-"$stringsize"`
    #echo "$element"
    
    #Remove everything after " INSTALLED..."
    startinstalled=$(strindex "$element" "$enddelimiterkeyword")
    element=`echo "$element" | cut -c1-"$startinstalled"`
    echo "$element"

    #If the package is not referenced in 'ignoredpackages', 'add to packagestoupgrade'
    ignorethispackage=false;
    for ignoredpackage in "${ignoredpackages[@]}"
    do
        # Each line is of this form: PROGRAM: xorg INSTALLED: 1:7.7+1ubuntu8 AVAILABLE: 1:7.7+1ubuntu8.1
        packageindex=$(strindex "$element" "$ignoredpackage")
        if [ $packageindex -ne "-1" ]; then
            #echo "[" `date +%Y-%m-%d_%R` "]" "Package $element won't be updated"
            ignorethispackage=true;
            break;
        fi

    done

    # Add the package
    if [ $ignorethispackage == false ]; then
        packagestoupgrade=(${packagestoupgrade[@]} "$element")
        #echo "[" `date +%Y-%m-%d_%R` "]" "Package $element will be updated"
    fi

    #echo "-----"

done

#################################################################
# Building the apt-get command                                  #
# PROBLEM: Altough the pattern were excluded, I still have their#
# dependencies.                                                 #
#################################################################
echo "[" `date +%Y-%m-%d_%R` "]" "List of packages to upgrade:"

updatestring="apt-get install"
    for element in "${packagestoupgrade[@]}"
    do
        echo "$element"
        updatestring=$updatestring" $element"
    done

echo "[" `date +%Y-%m-%d_%R` "]" "apt-get install command:"
echo "$updatestring"