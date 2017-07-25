#!/bin/bash

set -e

function up-pods() {
  CONFIG_PATH=$(cd `dirname ${BASH_SOURCE}`; pwd)/config/
  kubectl create -f ${CONFIG_PATH}flannel-rbac.yaml --namespace=kube-system
  kubectl create -f ${CONFIG_PATH}flannel.yaml

  kubectl create -f ${CONFIG_PATH}heapster-standalone.yaml
  kubectl create -f ${CONFIG_PATH}dashboard.yaml
}

function provision-master() {
  ssh -t $1 "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
    set -e
    sudo kubeadm init --kubernetes-version ${KUBERNETES_VERSION} --pod-network-cidr=10.244.0.0/16 --token ${token} --token-ttl ${token_ttl}
    mkdir -p \$HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config
    sudo chown $(id -u):$(id -g) \$HOME/.kube/config

    source \$HOME/kubernetes/utils.sh
    up-pods
  '"
}

function provision-masterandworker() {
  ssh -t $1 "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
    set -e
    sudo kubeadm init --kubernetes-version ${KUBERNETES_VERSION} --pod-network-cidr=10.244.0.0/16 --token ${token} --token-ttl ${token_ttl}
    mkdir -p \$HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf \$HOME/.kube/config
    sudo chown $(id -u):$(id -g) \$HOME/.kube/config

    kubectl taint nodes --all node-role.kubernetes.io/master-

    echo -e "[Service]\\\\nEnvironment=KUBELET_EXTRA_ARGS=--feature-gates=Accelerators=true" > my_kubelet.conf
    sudo chmod 640 my_kubelet.conf
    sudo chown root:root my_kubelet.conf
    sudo mv my_kubelet.conf /etc/systemd/system/kubelet.service.d/
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet.service

    source \$HOME/kubernetes/utils.sh
    up-pods
  '"
}

function provision-worker() {
  ssh -t $1 "echo ${SUDO_PASSWD} | sudo -S -- /bin/bash -i -ce '
    set -e
    sudo kubeadm join --token ${token} --skip-preflight-checks $2:6443

    echo -e "[Service]\\\\nEnvironment=KUBELET_EXTRA_ARGS=--feature-gates=Accelerators=true" > my_kubelet.conf
    sudo chmod 640 my_kubelet.conf
    sudo chown root:root my_kubelet.conf
    sudo mv my_kubelet.conf /etc/systemd/system/kubelet.service.d/
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet.service
  '"
}
