#!/bin/bash

set -e

if [[ -f "env.sh" ]]; then
  source env.sh
fi

export nodes=${nodes:-""}
nodes_array=($nodes)

num_nodes=${#nodes_array[@]}

hostnames=""
for ((i=num_nodes-1; i>=0; i--))
do
  this_hostname=$(echo `ssh -t ${nodes_array[i]} 'echo ${HOSTNAME}'` | tr -d "\r")
  hostnames="${hostnames} ${this_hostname}"
done
echo $hostnames
for hostname in ${hostnames}
do
  ssh -t ${nodes_array[0]} " /bin/bash -i -c '
    kubectl drain ${hostname} --delete-local-data --force --ignore-daemonsets
    kubectl delete node ${hostname}
  '"
done

for node in ${nodes}
do
  ssh -t ${node} "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce 'sudo kubeadm reset'"
done
