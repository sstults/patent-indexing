#/usr/bin/bash

# Step 1: Bitch and moan.
if [ $# -lt 2 ]
then
  echo
  echo "Usage: convert.sh uspatent.xml solrready.xml"
  exit 0
fi  

# Step 2: Remove all the doctype declirations from the file.
# then wrap the file in "patents" tags so that it is well formed.
sed -e '/^<!DOCTYPE.*/d' -e '/^<?xml/d' -e '3i\
<patents>' -e '$a\
</patents>' $1 > "tmp.xml"

# Step 3: Execute the transformation
xsltproc convert.xsl "tmp.xml" > $2

# Step 4: post the results to Solr.
#URL=http://localhost:8983/solr/us_patent_grant/update
#curl $URL --data-binary $2 -H 'Content-type:application/xml' 
#curl $URL --data-binary '<commit/>' -H 'Content-type:application/xml'


exit 0