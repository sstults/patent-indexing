#!/bin/bash

#
# NODE INITIALIZATION
#

sudo mkdir -p /media/ephemeral1
sudo mount /dev/xvdb2 /media/ephemeral1

sudo mkdir -p /media/ephemeral0/data
sudo mkdir -p /media/ephemeral1/data

sudo chmod 777 /media/ephemeral0/data
sudo chmod 777 /media/ephemeral1/data

sudo chown ec2-user:ec2-user /media/ephemeral0/data
sudo chown ec2-user:ec2-user /media/ephemeral1/data

echo "ec2-user:  sstults@o19s.com" | sudo tee -a /etc/aliases
sudo newaliases

sudo cp ~/patent-indexing/tange.repo /etc/yum.repos.d/
sudo yum -y install parallel
sudo yum -y install git

#
# Solr
#
sudo mkdir -p /var/log/solr
sudo chown ec2-user:ec2-user /var/log/solr
git clone git@github.com:sstults/patent-indexing.git
cd ~/patent-indexing/solr
sudo ln -s /home/ec2-user/patent-indexing/solr/jetty /etc/default/jetty
sudo ln -s /home/ec2-user/patent-indexing/solr/jetty6.sh /etc/init.d/jetty
sudo service jetty start
