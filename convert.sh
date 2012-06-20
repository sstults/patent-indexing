#/usr/bin/bash

# Step 1: Bitch and moan.
if [ $# -lt 2 ]
then
  echo
  echo "Usage: convert.sh uspatent.xml solrready.xml"
  exit 0
fi  

before="$(date +%s)"

log()
{
    # might do something interesting here, but for now it's good for trimming STDOUT
    if [ "$LOGGING" == "true" ]; then
        echo $@
    fi
}

benchmark() 
{
    after="$(date +%s)"
    elapsed_seconds="$(expr $after - $before)"
    log "Total Time: ${elapsed_seconds} sec"
}

log "  1. Removing xml and doctype declarations from the patent file."
sed -e '/^<!DOCTYPE.*/d' -e '/^<?xml/d' > "lump.xml" $1
sed -i 's/dtd-version="v4.2 2006-08-23"//g' "lump.xml"

log "  2. Splitting large file up into 1000 document chunks"
# Step 3: Split the single large file into chunks of 1000 documents each.
awk '/<us-patent-grant/{count++;}count==250{close("tmp"fc".xml");count=1;fc++;}count{f="tmp"fc".xml";print $0 > f}' lump.xml

# Step four, transform each chunk, and concatinate the result into a single json file.
rm -f lump.xml
rm -f lump.bak
rm -f $2
log "  3. Processing files"
for f in tmp*.xml 
do
  log "      - Processing $f file..."
  sed -i -e '1i <patents>' -e '$a </patents>' $f

  java -cp saxon9he.jar net.sf.saxon.Transform -s:$f -xsl:convert.xsl >> $2

#Parsing stylesheet convert.xsl took 1 ms
#Parsing document tmp1.xml took 2755 ms
#Applying stylesheet took 274779 ms

  #xsltproc -timing convert.xsl $f >> $2
  rm -f $f
  # take action on each file. $f store current file name
done

# Now, escape the quotes around all the attributes in the html.
sed -i 's/=\"\([^\"]*\)\"/=\\\"\1\\\"/g' $2
# now git rid of all the whitespace
sed -i '/^$/d' $2 

# Step 4: post the results to Solr.
#URL=http://localhost:8983/solr/us_patent_grant/update
#curl $URL --data-binary $2 -H 'Content-type:application/xml' 
#curl $URL --data-binary '<commit/>' -H 'Content-type:application/xml'

rm -f *.bak

benchmark

exit 0
