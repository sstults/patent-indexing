#!/bin/bash

TIFF_COUNT=`find /media/ephemeral0/images -name '*.tif' | wc -l`
LOOP_COUNTDOWN=$TIFF_COUNT

for file in `find /media/ephemeral0/images -name '*.tif'`
do
  echo "$LOOP_COUNTDOWN of $TIFF_COUNT to go" > ~/doing/tiff_count
  newdir=`expr "$file" : '\(.*\)\.tif'`
  basename=`basename "$file" .tif`
  reldir=`expr "$newdir" : "/media/ephemeral0/images/[^/]*\(.*\)"`

  echo "mkdir $newdir"
  mkdir $newdir

  echo "mkdir ${newdir}/150x"
  mkdir ${newdir}/150x

  echo "mkdir ${newdir}/450x"
  mkdir ${newdir}/450x

  echo "cd $newdir"
  cd $newdir

  echo "convert ../`basename $file` $basename.png"
  convert ../`basename $file` %d.png

  echo "mogrify -format png -path 150x -thumbnail 150x *.png"
  mogrify -format png -path 150x -thumbnail 150x *.png

  echo "mogrify -format png -path 450x -thumbnail 450x *.png"
  mogrify -format png -path 450x -thumbnail 450x *.png

  for i in $( find . -name '*.png' ); do
    echo item: $i:
    png=`expr $i : "\./\(.*\)"`
    echo "pushing $png to $reldir/$png on s3"
    echo "in `pwd`"
    echo $(/usr/bin/s3cmd put --acl-public --guess-mime-type $i s3://grant-images$reldir/$png)
  done
  echo "rm ../`basename $file`"
  rm ../`basename $file`
  let "LOOP_COUNTDOWN = $LOOP_COUNTDOWN - 1"
done
echo "$LOOP_COUNTDOWN of $TIFF_COUNT to go" > ~/doing/tiff_count

