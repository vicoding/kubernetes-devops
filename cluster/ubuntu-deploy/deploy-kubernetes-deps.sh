#!/bin/bash

DOWNLOAD_TIMEOUT=${DOWNLOAD_TIMEOUT:-60}

PACKAGE_PATH=${PACKAGE_PATH:-$HOME/dashboard_packages}

IMAGE_PATH=${PACKAGE_PATH}/images

PAUSE_VERSION=${PAUSE_VERSION:-2.0}
EXECHEALTHZ_AMD64_VERSION=${EXECHEALTHZ_AMD64_VERSION:-1.1}
KUBEDNS_AMD64_VERSION=${KUBEDNS_AMD64_VERSION:-1.6}
KUBE_DNSMASQ_AMD64_VERSION=${KUBE_DNSMASQ_AMD64_VERSION:-1.3}
DASHBOARD_VERSION=${DASHBOARD_VERSION:-1.1.1}
HEAPSTER_VERSION=${HEAPSTER_VERSION:-canary}
HEAPSTER_INFLUXDB_VERSION=${HEAPSTER_INFLUXDB_VERSION:-0.5}
HEAPSTER_GRAFANA_VERSION=${HEAPSTER_GRAFANA_VERSION:-2.6.0-2}

function get_kubernetes_deps_tar() {

  echo "Package path: ${PACKAGE_PATH}"

  echo -n "get easy-rsa.tar.gz"
  if [ ! -f ${PACKAGE_PATH}/kubernetes/easy-rsa.tar.gz ]; then
    pushd `pwd` >& /dev/null
    cd ${PACKAGE_PATH}
    curl -L -O https://sstorage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz -m ${DOWNLOAD_TIMEOUT} >& /dev/null
    if [ $? -ne 0 ]; then
      echo " ... failed"
      echo " please find another resource for the package - easy-rsa.tar.gz"
      echo " download it and put it to the path: ${PACKAGE_PATH}/kubernetes"
      popd >& /dev/null
      exit 110
    else
      popd >& /dev/null
    fi
  fi
  echo " ... done"

  echo -n "get flannel"
  if [ ! -f ${PACKAGE_PATH}/kubernetes/flannel-${FLANNEL_VERSION}-linux-amd64.tar.gz ]; then
    wget https://github.com/coreos/flannel/releases/download/v${FLANNEL_VERSION}/flannel-${FLANNEL_VERSION}-linux-amd64.tar.gz -P ${PACKAGE_PATH}/kubernetes >& /dev/null
    if [ $? -ne 0 ]; then
      echo " ... failed"
      echo " please find another resource for the package - flannel-${FLANNEL_VERSION}-linux-amd64.tar.gz"
      echo " download it and put it to the path: ${PACKAGE_PATH}/kubernetes"
      exit 110
    fi
  fi
  echo " ... done"

  echo -n "get etcd"
  if [ ! -f ${PACKAGE_PATH}/kubernetes/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz ]; then
    wget https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etc-v${ETCD_VERSION}-linux-amd64.tar.gz -P ${PACKAGE_PATH}/kubernetes >& /dev/null
    if [ $? -ne 0 ]; then
      echo " ... failed"
      echo " please find another resource for the package - etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
      echo " download it and put it to the path: ${PACKAGE_PATH}/kubernetes"
      exit 110
    fi
  fi
  echo " ... done"

  echo -n "get kubernetes"
  if [ ! -f ${PACKAGE_PATH}/kubernetes/kubernetes-v${KUBE_VERSION}.tar.gz ]; then
    wget https://github.com/kubernetes/kubernetes/releases/download/v${KUBE_VERSION}/kubernetes.tar.gz -O kubernetes-v${KUBE_VERSION}.tar.gz -P ${PACKAGE_PATH}/kubernetes >& /dev/null
    if [ $? -ne 0 ]; then
      echo " ... failed"
      echo " please find another resource for the package - kubernetes-v${KUBE_VERSION}.tar.gz"
      echo " download it and put it to the path: ${PACKAGE_PATH}/kubernetes"
      exit 110
    fi
  fi
  echo " ... done"
}

## 导入dns插件镜像, 导入顺序根据skydns-rc.yaml中的镜像下载顺序决定
function import_addons_images_dns() {
  sudo docker load < ${IMAGE_PATH}/pause-${PAUSE_VERSION}.tar
  sudo docker load < ${IMAGE_PATH}/exechealthz-amd64-${EXECHEALTHZ_AMD64_VERSION}.tar
  sudo docker load < ${IMAGE_PATH}/kubends-amd64-${KUBEDNS_AMD64_VERSION}.tar
  sudo docker load < ${IMAGE_PATH}/kube-dnsmasq-amd64-${KUBE_DNSMASQ_AMD64_VERSION}.tar
} 

## 导入dashboard插件镜像
function import_addons_images_dashboard() {
  sudo docker load < ${IMAGE_PATH}/kubernetes-dashboard-amd64-v${DASHBOARD_VERSION}.tar
}
