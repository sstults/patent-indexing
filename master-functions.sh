#!/bin/bash

MAX_FORK=5
MAX_NODES=2
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=false"

start_nodes() {
    ec2-run-instances ami-1b814f72   \
        --block-device-mapping '/dev/sdb=snap-48adde35::true'   \
        --block-device-mapping '/dev/sdi1=:10:false'   \
        --block-device-mapping '/dev/sdi2=:10:false'   \
        --block-device-mapping '/dev/sdi3=:20:false'   \
        --instance-type m1.large   \
        --key uspto-jenkins     \
        --instance-count $MAX_NODES  \
        --group default  > ~/run-output
}

make_instance_list() {
    cat ~/run-output | \
        grep uspto-jenkins | \
        cut -f 2 > ~/instance_list
}

make_addr_list() {
    cat ~/instance_list | \
        xargs ec2-describe-instances | \
        grep INSTANCE | \
        cut -f 5 > ~/instance_addr_list
}

terminate_instances() {
    cat ~/instance_list | \
        xargs -P $MAX_FORK ec2-terminate-instances
    rm ~/instance_addr_list
    rm ~/instance_list
    rm ~/run-output
}

distribute_init() {
    cat ~/instance_addr_list | \
        sed 's/\(.*\)/\1:/' | \
        xargs -P $MAX_FORK -n 1 scp $SSH_ARGS \
            ~/dir_search/aws/index-node/node-init.sh
    cat ~/instance_addr_list | \
        sed 's/\(.*\)/\1:/' | \
        xargs -P $MAX_FORK -n 1 scp $SSH_ARGS \
            ~/dir_search/aws/index-node/home:tange.repo
        
}

distribute_bins() {
    cat ~/instance_addr_list | \
        sed 's/\(.*\)/\1:\~\/bin/' | \
        xargs -P $MAX_FORK -n 1 scp -r $SSH_ARGS \
            ~/dir_search/aws/*
}

node_init() {
    cat ~/instance_addr_list | \
        sed 's/\(.*\)/\1 sh node-init.sh/' | \
        xargs -P $MAX_FORK -n 3 ssh -t -t $SSH_ARGS
}

get_status() {
    cat ~/instance_addr_list | \
        sed 's|\(.*\)|\1 sh bin/index-node/convert-status.sh|' | \
        xargs -P $MAX_FORK -n 3 ssh $SSH_ARGS 2>/dev/null
}

get_node_todos() {
    cat ~/instance_addr_list | \
        sed 's|\(.*\)|\1 find ~/todo -type f|' | \
        xargs -P $MAX_FORK -n 5 ssh $SSH_ARGS 2>/dev/null
}

get_node_doings() {
    cat ~/instance_addr_list | \
        sed 's|\(.*\)|\1 find ~/doing -type f|' | \
        xargs -P $MAX_FORK -n 5 ssh $SSH_ARGS 2>/dev/null
}

get_node_dones() {
    cat ~/instance_addr_list | \
        sed 's|\(.*\)|\1 find ~/done -type f|' | \
        xargs -P $MAX_FORK -n 5 ssh $SSH_ARGS 2>/dev/null
}

ready_nodes() {
    start_nodes
    make_instance_list
    sleep 480
    make_addr_list
    distribute_init
    node_init
    distribute_bins
    parallel --nonall --sshloginfile instance_addr_list cd bin/index-node ';' nohup unzip categories.zip
}
