#/bin/bash
startdelimiterkeyword="PROGRAM: "


s='id;some text here with possible ; inside'
IFS=';' read -r id string <<< "$s"
echo "$id"
echo "$string"

strindex() { 
    x="${1%%$2*}"
    [[ $x = $1 ]] && echo -1 || echo ${#x}
  }

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
    echo $startprogram
    echo $endprogram
    echo "$element" | cut -c"$endprogram"-"$stringsize"
    echo "$element"
    echo "-----"
done