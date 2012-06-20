#!/bin/bash

START=$(date +%s)

SCRIPT_DIR=${SCRIPT_DIR:-~/patent-indexing}

# Unzip categories.zip if necessary
if [ ! -f ${SCRIPT_DIR}/categories.xml ] ; then
    pushd ${SCRIPT_DIR}
    unzip categories.zip
    popd
fi

for url in $@
do
    file=`echo ${url} | awk -F '/' '{print $7}'`
    filebase=`echo ${file} | awk -F '.' '{print $1}'`
    mkdir $filebase
    ln -s ${SCRIPT_DIR}/categories.xml ${filebase}/categories.xml
    ln -s ${SCRIPT_DIR}/saxon9he.jar ${filebase}/saxon9he.jar
    ln -s ${SCRIPT_DIR}/convert.xsl ${filebase}/convert.xsl
    ln -s ${SCRIPT_DIR}/cals_table.xsl ${filebase}/cals_table.xsl
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

