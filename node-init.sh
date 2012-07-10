#!/bin/bash

#
# NODE INITIALIZATION
#

sudo mkdir -p /media/ebs
sudo mkfs.ext4 /dev/sdi > /dev/null
sudo mount /dev/sdi /media/ebs
sudo mkdir -p /media/ebs/data
sudo chmod 777 /media/ebs/data
sudo chown ec2-user:ec2-user /media/ebs/data

echo "ec2-user:  sstults@o19s.com" | sudo tee -a /etc/aliases
sudo newaliases

sudo cp ~/patent-indexing/tange.repo /etc/yum.repos.d/
sudo yum -y -q install parallel

#
# Solr
#
sudo mkdir -p /var/log/solr
sudo chown ec2-user:ec2-user /var/log/solr
cd ~/patent-indexing/solr
sudo ln -s /home/ec2-user/patent-indexing/solr/jetty /etc/default/jetty
sudo ln -s /home/ec2-user/patent-indexing/solr/jetty6.sh /etc/init.d/jetty
sudo service jetty start
