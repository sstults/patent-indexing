#!/bin/bash

MAX_FORK=5
MAX_NODES=2
SSH_ARGS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=false"

# I'm assuming that the EC2_PRIVATE_KEY and EC2_CERT environment variables are
# set to something appropriate

start_nodes() {
    ec2-run-instances ami-e565ba8c   \
        --block-device-mapping '/dev/sdb1=ephemeral0'   \
        --block-device-mapping '/dev/sdb2=ephemeral1'   \
        --instance-type m1.large   \
        --key uspto-jenkins     \
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
}

make_addr_list() {
    cat ~/instance_list | \
        parallel 'ec2-describe-instances {} | \
        grep INSTANCE | \
        cut -f 5 >> ~/instance_addr_list'
}

make_ssh_login_file() {
    mkdir -p ~/.parallel
    cat ~/instance_addr_list | \
        sed 's/\(.*\)/ubuntu@\1/' > ~/.parallel/sshloginfile
}

terminate_instances() {
    cat ~/instance_list | \
        parallel 'ec2-terminate-instances {}'
    rm ~/instance_addr_list
    rm ~/instance_list
    rm ~/start_nodes.out
    rm ~/.parallel/sshloginfile
}

distribute_init() {
    cat ~/instance_addr_list | \
        parallel "scp -r patent-indexing {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel "scp -r .aws_creds {}: 2>&1 | grep -v 'Permanently added'"
    cat ~/instance_addr_list | \
        parallel "scp .bash_profile {}: 2>&1 | grep -v 'Permanently added'"
}

distribute_solr() {
    cat ~/instance_addr_list | \
        parallel "scp -r solr {}: 2>&1 | grep -v 'Permanently added'"
}

node_init() {
    echo "sh patent-indexing/node-init.sh" | parallel --tag --onall -S ..
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
    wait_for_pending_nodes
    make_addr_list
    make_ssh_login_file
    distribute_init
    node_init
    distribute_bins
    parallel --nonall --sshloginfile instance_addr_list cd bin/index-node ';' nohup unzip categories.zip
}
