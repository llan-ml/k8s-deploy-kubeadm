#!/bin/bash

set -e

if [[ -f "env.sh" ]]; then
  source env.sh
fi

export nodes=${nodes:-""}
nodes_array=($nodes)
num_nodes=${#nodes_array[@]}

export SUDO_PASSWD=${SUDO_PASSWD:-""}

for ((i=0; i<num_nodes; i++))
do
  ssh -t ${nodes_array[$i]} "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
    set -e
    apt update && apt -y upgrade
    mv /etc/apt/sources.list.d/kubernetes.list.bak /etc/apt/sources.list.d/kubernetes.list
    "'proxy_on apt'"
  '"
done

for ((i=0; i<num_nodes; i++))
do
  ssh -t ${nodes_array[$i]} "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
    set -e
    apt update && apt -y upgrade
  '"
  echo "(Updated) Index: $i  Node:${nodes_array[$i]}"
done

echo "=====Update finished====="

for ((i=0; i<num_nodes; i++))
do
  ssh -t ${nodes_array[$i]} "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
    set -e
    mv /etc/apt/sources.list.d/kubernetes.list /etc/apt/sources.list.d/kubernetes.list.bak
    "'proxy_off apt'"
  '"
done
