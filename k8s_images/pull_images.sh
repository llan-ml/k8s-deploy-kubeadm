#!/bin/bash

set -e

if [[ -f "../env.sh" ]]; then
  source ../env.sh
else
  echo "Not Found env.sh"
  exit 2
fi

export nodes=${nodes:-""}
export SUDO_PASSWD=${SUDO_PASSWD:-""}

gcr_prefix="gcr.io/google_containers/"
K8S_VERSION="v1.6.0"
PAUSE_VERSION="3.0"
DNS_VERSION="1.14.4"
ETCD_VERSION="3.0.17"
FLANNEL_VERSION="v0.8.0-amd64"
DASHBOARD_VERSION="v1.6.1"
HEAPSTER_VERSION="v1.3.0"
ARCH="amd64"

TENSORFLOW_VERSION="1.2.1-gpu"

docker_image_names="\
${gcr_prefix}kube-apiserver-${ARCH}:${K8S_VERSION} \
${gcr_prefix}kube-controller-manager-${ARCH}:${K8S_VERSION} \
${gcr_prefix}kube-scheduler-${ARCH}:${K8S_VERSION} \
${gcr_prefix}kube-proxy-${ARCH}:${K8S_VERSION} \
${gcr_prefix}pause-${ARCH}:${PAUSE_VERSION} \
${gcr_prefix}etcd-${ARCH}:${ETCD_VERSION} \
${gcr_prefix}k8s-dns-sidecar-${ARCH}:${DNS_VERSION} \
${gcr_prefix}k8s-dns-kube-dns-${ARCH}:${DNS_VERSION} \
${gcr_prefix}k8s-dns-dnsmasq-nanny-${ARCH}:${DNS_VERSION} \
${gcr_prefix}kubernetes-dashboard-${ARCH}:${DASHBOARD_VERSION} \
${gcr_prefix}heapster-${ARCH}:${HEAPSTER_VERSION} \
quay.io/coreos/flannel:${FLANNEL_VERSION} \
nvidia/cuda:latest \
tensorflow/tensorflow:${TENSORFLOW_VERSION}"


local_registry="lindockerryan/docker-library:"

for node in $nodes
do
  for image in ${docker_image_names}
  do
    num_fields=$(echo $image | awk -F/ '{printf NF}')
    if [[ ${num_fields} = "3" ]]; then
      registry=$(echo $image | awk -F/ '{printf $1}')
      namespace=$(echo $image | awk -F/ '{printf $2}')
      base=$(echo $image | awk -F/ '{printf $3}' | awk -F: '{printf $1}')
      tag=$(echo $image | awk -F/ '{printf $3}' | awk -F: '{printf $2}')
      ssh -t $node "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
        set -e
        if [[ ! \$(sudo docker images | grep ${registry}/${namespace}/${base} | grep ${tag}) ]]; then
          image_pullname=${local_registry}${base}
          sudo docker pull ${image_pullname}
          sudo docker tag ${image_pullname} ${image}
          sudo docker rmi ${image_pullname}
        fi
      '"
    elif [[ ${num_fields} = "2" ]]; then
      namespace=$(echo $image | awk -F/ '{printf $1}')
      base=$(echo $image | awk -F/ '{printf $2}' | awk -F: '{printf $1}')
      tag=$(echo $image | awk -F/ '{printf $2}' | awk -F: '{printf $2}')
      ssh -t $node "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
        set -e
        if [[ ! \$(sudo docker images | grep ${namespace}/${base} | grep ${tag}) ]]; then
          sudo docker pull ${image}
        fi
      '"
    else
      echo "Unrecognized image: ${image}"
      exit 2
    fi
  done
done

