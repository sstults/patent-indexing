#!/bin/bash

START=$(date +%s)

for url in $@
do
    file=`echo ${url} | awk -F '/' '{print $7}'`
    filebase=`echo ${file} | awk -F '.' '{print $1}'`
    mkdir $filebase
    ln -s `pwd`/categories.xml `pwd`/${filebase}/categories.xml
    ln -s `pwd`/saxon9he.jar `pwd`/${filebase}/saxon9he.jar
    ln -s `pwd`/convert.xsl `pwd`/${filebase}/convert.xsl
    ln -s `pwd`/cals_table.xsl `pwd`/${filebase}/cals_table.xsl
    (
    cd $filebase
    wget -q ${url} -o wget.log
    ../fix-zip-filenames.sh
    #echo ${file}
    unzip ${file}
    ../convert.sh ${filebase}.xml ${filebase}.json
    (SOLR_CORE=${filebase}; ../post_json.sh ${file}.json > /dev/null)
    #####rm -f ${file}.json ${filebase}.xml ${file}
    )

    END=$(date +%s)
    DIFF=$(( $END - $START ))
    echo "${file} Processed in $DIFF seconds"
done

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Total time: $DIFF seconds"

