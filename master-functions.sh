#!/bin/bash

MAX_FORK=${MAX_FORK:-5}
MAX_NODES=${MAX_NODES:-2}
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=false"

# I'm assuming that the EC2_PRIVATE_KEY and EC2_CERT environment variables are
# set to something appropriate

start_nodes() {
    ec2-run-instances ami-e565ba8c   \
        --block-device-mapping '/dev/sdi=:9:false'   \
        --instance-type ${1:-m1.medium}   \
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

# This is only needed to put the tar into S3
prepare_distribution() {
    tar -cjf patent-indexing-1.0.tar.bz2 patent-indexing
    s3put -b grant-xml patent-indexing-1.0.tar.bz2
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
        parallel -j50 "scp /etc/yum.repos.d/s3tools.repo {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel  -j50 "ssh -t -t {} sudo mv s3tools.repo /etc/yum.repos.d"
    cat ~/instance_addr_list | \
        parallel  -j50 "ssh -t -t {} sudo yum -q -y install s3cmd"
    cat ~/instance_addr_list | \
        parallel -j50 "scp .s3cfg {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel  -j50 "ssh -t -t {} sudo yum -q -y install git"
        
    # Clone from Github is bombing. rsync? bittorrent? s3? custom ami? ebs made from a snapshot?
    # local repo clone takes too long
    parallel --nonall -j50 -S .. s3cmd get s3://grant-xml/patent-indexing-1.0.tar.bz2 patent-indexing-1.0.tar.bz2
    parallel --nonall -j50 -S .. tar -jxf patent-indexing-1.0.tar.bz2
    # Just to be sure
    parallel --nonall -j50 -S .. cd patent-indexing ";" git pull
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
    start_nodes ${1:-m1.medium}
    make_instance_list
    wait_for_pending_nodes
    terminate_nonpassing_nodes
    # need to bring node count back up to max
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

stage2() {
    # TODO: Use tags to mark these volumes when they're created instead of the magic "9" size
    ec2-describe-volumes --filter "size=9" | \
        grep VOLUME | cut -f 2 > ~/stage1-vols
    VOLS=`wc -l ~/stage1-vols | cut -f 1 -d " "`
    MAX_NODES=`echo "$VOLS/5" | bc`
    start_nodes m1.large
    make_instance_list
    wait_for_pending_nodes
    terminate_nonpassing_nodes
    make_addr_list
    make_ssh_login_file
    distribute_init
    node_init
    cat ~/stage1-vols | xargs -n 5 echo | paste ~/instance_addr_list  - | grep vol > ~/stage1-assignments
    parallel -j50 --tag --nonall -S .. ls /var/log/solr/'*.log'
    cat stage1-assignments | awk 'BEGIN { FS = "[ \t]*|[ \t]+" }{ print "ssh -t -t", $1, "sh patent-indexing/ebs-to-ebs.sh", $2, $3, $4, $5, $6}' > stage1-commands
    parallel -j50 -a stage1-commands --tag
}

stage3() {

    wc -l stage2-vols

    head -n 12 instance_list > stage3_instance_list
    tail -n $(( 60 - 12 )) instance_list
    tail -n $(( 60 - 12 )) instance_list  | wc -l
    tail -n $(( 60 - 12 )) instance_list  > expiring-nodes_stage2
    cp expiring-nodes_stage2 instance_list
    terminate_instances

    cp stage3_instance_list instance_list
    make_addr_list
    cat instance_addr_list
    make_ssh_login_file

    cat stage2-vols
    cat ~/stage2-vols | xargs -n 5 echo | paste ~/instance_addr_list  - | grep vol > ~/stage3-assignments
    cat stage3-assignments | awk 'BEGIN { FS = "[ \t]*|[ \t]+" }{ print "ssh -t -t", $1, "sh patent-indexing/ebs-to-ebs.sh", $2, $3, $4, $5, $6}' > stage3-commands
    cat stage3-commands | parallel -j50 -a stage1-commands --tag
}