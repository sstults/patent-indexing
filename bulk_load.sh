#!/bin/bash

START=$(date +%s)

for url in `wget -O - http://www.google.com/googlebooks/uspto-patents-grants-text.html -o wget.log | grep ipg0608 | awk '{print $2}' | sed -e 's/href="//' -e 's/">//' | sort -r | uniq`
do
    file=`echo ${url} | awk -F '/' '{print $7}'`
    wget -q ${url} -o wget.log
    mv ${file}* ${file}
    echo ${file}
    unzip ${file}
    filebase=`echo ${file} | awk -F '.' '{print $1}'`
    ./convert.sh ${filebase}.xml ${file}.json
    ./post_json.sh ${file}.json >> /dev/null
    rm ${file}.json ${filebase}.xml ${file}

    END=$(date +%s)
    DIFF=$(( $END - $START ))
    echo "${file} Processed in $DIFF seconds"
done

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Total time: $DIFF seconds"

