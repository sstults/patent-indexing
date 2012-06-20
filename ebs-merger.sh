#!/bin/bash

# Creates an EBS volume and merges two indexes together

EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"
INDEX1_SIZE=`du -s /media/ephemeral0/data | cut -f 1`
INDEX2_SIZE=`du -s /media/ephemeral1/data | cut -f 1`
# do some funky math to give us some headway in our new volume
EBS_SIZE=`echo "((${INDEX1_SIZE} + ${INDEX2_SIZE})*3/2000000)+1" | bc`

EC2_PRIVATE_KEY=~/.aws_creds/pk-SS5MTCPI5NCLXEBYWAXPLRKQJRXWDPW7.pem
EC2_CERT=~/.aws_creds/cert-SS5MTCPI5NCLXEBYWAXPLRKQJRXWDPW7.pem
export EC2_PRIVATE_KEY EC2_CERT

echo $INDEX1_SIZE $INDEX2_SIZE $EBS_SIZE
#ec2-create-volume
ec2-describe-instances