#!/bin/bash

#
# NODE INITIALIZATION
#

mkdir -p ~/todo
mkdir -p ~/doing
mkdir -p ~/done

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

