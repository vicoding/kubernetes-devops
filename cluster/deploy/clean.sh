#!/bin/bash

function clean() {
  sudo /etc/init.d/etcd stop
  
  sudo rm -rf \
    /opt/bin/etcd* \
    /etc/init/etcd.conf \
    /etc/init.d/etcd \
    /etc/default/etcd
  
  sudo rm -rf /infra*
  sudo rm -rf /srv/kubernetes
  
  sudo /etc/init.d/flanneld stop
  sudo rm -rf /var/lib/kubelet
  
  sudo /etc/init.d/kube-apiserver stop
  sudo /etc/init.d/kube-controller-manager stop
  sudo /etc/init.d/kubelet stop
  sudo /etc/init.d/kube-proxy stop
  sudo /etc/init.d/kube-scheduler stop
  
  sudo rm -f \
    /opt/bin/kube* \
    /opt/bin/flanneld \
    /etc/init/kube* \
    /etc/init/flanneld.conf \
    /etc/init.d/kube* \
    /etc/init.d/flanneld \
    /etc/default/kube* \
    /etc/default/flanneld
  
  sudo rm -rf ~/kube
  sudo rm -f /run/flannel/subnet.env
  
  echo "clean binaries"
  sudo rm -rf ubuntu/binaries
}
