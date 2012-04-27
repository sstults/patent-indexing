#!/bin/bash

TIFF_COUNT=`find /media/ephemeral0/images -name '*.tif' | wc -l`

PNG_COUNT=`find /media/ephemeral0/images -name '0.png' | grep -v 450x | grep -v 150x | wc -l`

echo "$(($TIFF_COUNT - $PNG_COUNT)) left of $TIFF_COUNT"
