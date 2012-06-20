#!/bin/bash

if [ $# -lt 2 ]
then
  echo
  echo "Usage: single_load.sh patent_grant_url /path/to/solr/data/dir"
  exit 0
fi  

START=$(date +%s)

SCRIPT_DIR=${SCRIPT_DIR:-~/patent-indexing}

# Unzip categories.zip if necessary
if [ ! -f ${SCRIPT_DIR}/categories.xml ] ; then
    pushd ${SCRIPT_DIR}
    unzip categories.zip
    popd
fi

url=$1
data_dir=$2


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
${SCRIPT_DIR}/fix-zip-filenames.sh
#echo ${file}
unzip ${file}
${SCRIPT_DIR}/convert.sh ${filebase}.xml ${filebase}.json


CURL="http://localhost:8983/solr/admin/cores?action=CREATE"
IDIR="instanceDir=/home/ec2-user/solr/dir_search_cores/us_patent_grant_v2_0/"
CFILE="config=solrconfig.xml"
SFILE="schema=schema.xml"
DDIR="dataDir=${data_dir}"
curl "${CURL}&name=${filebase}&${IDIR}&${CFILE}&${SFILE}&${DDIR}"



(SOLR_CORE=${filebase}; ${SCRIPT_DIR}/post_json.sh ${filebase}.json > /dev/null)
#####rm -f ${file}.json ${filebase}.xml ${file}

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Total time: $DIFF seconds"

