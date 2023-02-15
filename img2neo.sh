#!/bin/bash
png=$1
size=$2
depth=$3
rm -rf asciiLogo.txt
echo "Preview:"
jp2a --colors --color-depth=$3 --height=$2 $1 
jp2a --colors --color-depth=$3 --height=$2 $1 | sed -e 's/\x1b\[\([0-9]\{1,\}\)m/${c\1}/g' > test.txt
foundColors=$(grep -o '\${c[0-9]\+}' test.txt | sed 's/\${c\|\}//g' | sort -u | tr '\n' ' ')
arr=($foundColors)
if [[ "${#arr[@]}" -gt 6 ]] then
    exit;
fi
asciiText=$(cat test.txt)
rm -rf test.txt
IFS=$'\n'
for line in $asciiText; do
    i=1;
    
    IFS=$' '
    for color in $foundColors; do
        line=$(echo $line | sed "s/\${c${color}}/\${c${i}}/g")
        ((i++))
    done

    echo $line >> 'asciiLogo.txt'
done