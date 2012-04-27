#!/bin/bash

# if there are no tasks in todo then exit(1)
TASK_COUNT=`find ~/todo -type f | wc -l`
if [ $TASK_COUNT -lt 1 ]
then
    exit 1
fi

# clear out the working folder and logs
rm -rf /media/ephemeral0/images/*
rm -rf ~/doing/log

# grab the next task from todo and move it to doing
NEXT_TASK=`find ~/todo -type f | head -n 1`
mv $NEXT_TASK ~/doing

# make a log directory
mkdir ~/doing/log

# pull down the zip
TASK_FILE=`find ~/doing -type f`
cd /media/ephemeral0/images
wget -nv -i $TASK_FILE --force-html

# fix the zip filename
sh ~/bin/image-node/fix-zip-filenames.sh

# unzip the file
unzip *.zip

# run the converter, saving the output
TASK_NUM=`basename $TASK_FILE`
sh ~/bin/image-node/tiff-converter.sh > ~/doing/log/${TASK_NUM}.log 2> ~/doing/log/${TASK_NUM}.err

# make a directory in done named for the task
mkdir ~/done/$TASK_NUM

# move the task and log to that folder
mv ~/doing/log/* ~/done/$TASK_NUM
mv ~/doing/$TASK_NUM ~/done/$TASK_NUM
