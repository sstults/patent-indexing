
#
# NODE STARTUP (RUN ON MASTER)
#
 
# Spins up "instance-count" number of nodes and saves the output for later reference
# (we'll need to awk the instance id so that we can map that to an IP)
ec2-run-instances ami-1b814f72   \
    --block-device-mapping '/dev/sda2=ephemeral0'   \
    --instance-type m1.large   \
    --key uspto-jenkins     \
    --instance-count 2  \
    --group  quicklaunch-1  > run-output

# This will let you scp a file to a machine without prompting to accept its host key
scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking ...........

#
# NODE INITIALIZATION (RUN ON NODES)
# (this is now in a separate file)
#

mkdir ~/bin

sudo mkdir /media/ephemeral0/tmp
sudo chmod 777 /media/ephemeral0/tmp
echo 'export MAGICK_TEMPORARY_PATH=/media/ephemeral0/tmp' >> ~/.bash_profile

sudo mkdir /media/ephemeral0/images
sudo chmod 777 /media/ephemeral0/images

sudo yum -y install ImageMagick

cd /etc/yum.repos.d
sudo wget http://s3tools.org/repo/RHEL_6/s3tools.repo
sudo yum -y install s3cmd

# need to add a line that scp's the node scripts to their bin directory

#
# NODE TASK (RUN ON NODES)
#

cd  /media/ephemeral0/images
wget http://commondatastorage.googleapis.com/patents/grant_multi_page_imgs/2009/USP2009w01-01.zip

fix-zip-filenames.sh
unzip USP2009w01-01.zip
rm USP2009w01-01.zip

tiff-converter.sh

# We either need to modify tiff-converter.sh to upload each grant when it's done
# or add a line here to upload all of them to S3 (that's what the s3cmd package is for)

# to upload each file we can use a curl command similar to this: (the
# first two params need to be altered to appropriate file names

curl -F "key=screenshots/current_screenshot.png" \
  -F "file=@test.png" \
  -F "acl=public-read" \
  -F "AWSAccessKeyId=AKIAJJ4LYGDXWBXEGWVQ" \
  -F
"Policy=eyJleHBpcmF0aW9uIjogIjIwMTItMDUtMDFUMDA6MDA6MDBaIiwKICAiY29uZGl0aW9ucyI6IFsgCiAgICAgIHsiYnVja2V0IjogImdyYW50LWltYWdlcyJ9LCAKICAgICAgWyJzdGFydHMtd2l0aCIsICIka2V5IiwgIiJdLAogICAgICB7ImFjbCI6ICJwdWJsaWMtcmVhZCJ9LAogICAgICBbInN0YXJ0cy13aXRoIiwgIiRDb250ZW50LVR5cGUiLCAiIl0sCiAgICAgIFsiY29udGVudC1sZW5ndGgtcmFuZ2UiLCAwLCAxMDQ4NTc2MDBdCiAgXQp9Cg=="
\
  -F "Signature=EEwrOPsZeuFkFCmvKbRW3zw2/Rc=" \
  -F "Content-Type=image/png" \
  https://grant-images.s3.amazonaws.com/

#
# JOB
#

# This is the general flow

#Start N nodes = min(number of tasks, max nodes)
start_nodes
#Make a list of the node instance id's
make_instance_list
#Make a list of the internal addresses of the instance id's
make_addr_list

#For each node:
#    init task with the google url of the file
#    start task

#While there are tasks
#    For each node:
#        check task                
        # ssh -i uspto-jenkins.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ip-10-12-122-227  bin/convert-status.sh 2>/dev/null
#        if task is done
#            collect output
#            init new task
#            start new task
 
# (when all the tasks are done) 
#For each node:
#    terminate node
terminate_instances        
