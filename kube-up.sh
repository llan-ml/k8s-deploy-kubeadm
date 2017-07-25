#!/bin/bash

if [[ -f "env.sh" ]]; then
  source env.sh
fi

if [[ -f "utils.sh" ]]; then
  source utils.sh
else
  echo "Not found \"utils.sh\""
  exit 2
fi

export nodes=${nodes:-""}
export roles=${roles:-""}
export roles_array=($roles)
export master_ip=""

i=0
for node in ${nodes}
do
  if [[ "${roles_array[${i}]}" = "m" ]]; then
    master_ip=${node}
    provision-master ${node}
  elif [[ "${roles_array[${i}]}" = "mw" ]]; then
    master_ip=${node}
    provision-masterandworker ${node}
  elif [[ "${roles_array[${i}]}" = "w" ]]; then
    provision-worker ${node} ${master_ip}
  fi
  ((i=i+1))
done
