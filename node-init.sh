#!/bin/bash

#
# NODE INITIALIZATION
#

mkdir ~/todo
mkdir ~/doing
mkdir ~/done

sudo mkdir /media/ephemeral0/bin
sudo chmod 777 /media/ephemeral0/bin
sudo chown ec2-user:ec2-user /media/ephemeral0/bin

ln -s /media/ephemeral0/bin ~/bin

echo "ec2-user:  sstults@o19s.com" | sudo tee -a /etc/aliases
sudo newaliases

#cd /etc/yum.repos.d/
#sudo wget http://download.opensuse.org/repositories/home:tange/CentOS_CentOS-5/home:tange.repo
sudo cp ~/home\:tange.repo /etc/yum.repos.d/
sudo yum -y install parallel


sudo mkfs.ext4 /dev/sdi1
sudo mkfs.ext4 /dev/sdi2
sudo mkfs.ext4 /dev/sdi3
sudo mkdir -m 000 /mnt/core0
sudo mkdir -m 000 /mnt/core1
sudo mkdir -m 000 /mnt/core2
sudo mount /dev/sdi1 /mnt/core0
sudo mount /dev/sdi2 /mnt/core1
sudo mount /dev/sdi3 /mnt/core2
