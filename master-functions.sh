#!/bin/bash

MAX_FORK=5
MAX_NODES=2
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=false"

# I'm assuming that the EC2_PRIVATE_KEY and EC2_CERT environment variables are
# set to something appropriate

start_nodes() {
    ec2-run-instances ami-e565ba8c   \
        --block-device-mapping '/dev/sdi=:9:false'   \
        --instance-type $1   \
        --key uspto-jenkins     \
        --availability-zone us-east-1a \
        --instance-count $MAX_NODES  \
        --group default  > ~/start_nodes.out
}

make_instance_list() {
    cat ~/start_nodes.out | \
        grep uspto-jenkins | \
        cut -f 2 > ~/instance_list
}

list_node_states() {
    cat ~/instance_list | \
        xargs  ec2-describe-instances | \
        grep INSTANCE | cut -f 6
}

wait_for_pending_nodes() {
    while [ `list_node_states | grep pending | wc -l` -gt 0 ]
    do
        sleep 15
    done
    # todo: wait for ssh smarter
    sleep 120
}

make_addr_list() {
    #NB: The way we do this is limited by the number of args you can feed to xargs
    cat ~/instance_list | \
        xargs ec2-describe-instances | \
        grep INSTANCE | \
        cut -f 5 > ~/instance_addr_list
}

make_ssh_login_file() {
    mkdir -p ~/.parallel
    cat ~/instance_addr_list | \
        sed 's/\(.*\)/\1/' > ~/.parallel/sshloginfile
}

terminate_instances() {
    cat ~/instance_list | \
        xargs ec2-terminate-instances
    rm ~/instance_addr_list
    rm ~/instance_list
    rm ~/start_nodes.out
    rm ~/.parallel/sshloginfile
    rm ~/.ssh/known_hosts
}

distribute_init() {
    # Doing this through git clone now so we don't have a single choke point
    #cat ~/instance_addr_list | \
    #    parallel "scp -r patent-indexing {}: 2>&1 | grep -v 'Permanently added'"
    
    # DANGER: I'M DOING THIS ON A CUSTOM NODE
    cat ~/instance_addr_list | \
        parallel -j50 "scp -r .aws_creds {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel -j50 "scp -r .ssh {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel -j50 "scp .bash_profile {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel  -j50 "ssh -t -t {} sudo yum -q -y install git"
    parallel --nonall -j50 -S .. git clone git@github.com:sstults/patent-indexing.git
}

node_init() {
    cat ~/instance_addr_list | \
        parallel -j50 "ssh -t -t {} sh patent-indexing/node-init.sh"
}

load_sample() {
    head -n $MAX_NODES patent-indexing/zip_urls.txt | \
        parallel --tag --use-cpus-instead-of-cores \
        -S .. sh patent-indexing/single_load.sh {}
}

terminate_nonpassing_nodes() {
    ec2-describe-instance-status | grep impaired | cut -f 2 > impaired
    
    # I wish we could just do the below as a separate job and continue
    # but I've noticed weird I/O blocking when running multiple ec2- programs
    cat impaired | xargs ec2-terminate-instances
    
    grep -v -f impaired instance_list > instance_list.tmp
    mv instance_list.tmp instance_list
}

ready_nodes() {
    start_nodes m1.medium
    make_instance_list
    wait_for_pending_nodes
    make_addr_list
    make_ssh_login_file
    distribute_init
    node_init
    # Do something interesting to show we're all up
    parallel -j50 --tag --nonall -S .. ls /var/log/solr/'*.log'
}

do_test() {
    time ready_nodes
    time load_sample
    cat ~/instance_addr_list | parallel -j50 "ssh -t -t {} sudo service jetty stop"
    cat ~/instance_addr_list | parallel -j50 "ssh -t -t {} sudo umount /media/ebs"
    parallel --nonall -j50 -S .. cd patent-indexing ";" git checkout solr/dir_search_cores/solr.xml
}

