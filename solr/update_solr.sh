#!/bin/sh
# download and install a updated version of Solr from Trunk CI build.

SOLR_BUILD_VERSION=apache-solr-4.0-2012-02-05_09-37-32.zip
SOLR_URL=https://builds.apache.org/view/S-Z/view/Solr/job/Solr-trunk/ws/artifacts/$SOLR_BUILD_VERSION

wget --no-check-certificate $SOLR_URL

unzip $SOLR_BUILD_VERSION  -d tmp

git rm -r apache-solr-4.0-trunk

rm -rf apache-solr-4.0-trunk
mv tmp/* apache-solr-4.0-trunk
rmdir tmp
rm $SOLR_BUILD_VERSION

rm -rf apache-solr-4.0-trunk/docs

# Now compile and install the latest BRS Query Parser
cd ../uspto-solr/BrsQueryParserPlugin
mvn clean package
cp target/BrsQueryParserPlugin*.jar ../../solr/apache-solr-4.0-trunk/contrib


echo "Please test the updated Solr and then do a git add!"