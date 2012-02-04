#!/bin/bash

for file in `ls *.zip?*`
do
	newfile=`echo ${file} | sed 's/\(\w*\.zip\)\W.*/\1/'`
	mv ${file} ${newfile}
done
