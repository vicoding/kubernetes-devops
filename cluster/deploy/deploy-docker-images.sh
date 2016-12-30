#!/bin/bash

set -x

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")

if [ -f $INSTALL_ROOT/deploy_env ]; then
  source $INSTALL_ROOT/deploy_env
fi

if [ -f $INSTALL_ROOT/config-default.sh ]; then
  source $INSTALL_ROOT/config-default.sh
fi

PACKAGE_PATH=${PACKAGE_PATH:-$HOME/dashboard_packages}

IMAGE_PATH=$PACKAGE_PATH/images

function load_images_all() {
  ls $IMAGE_PATH | while read image ; do sudo docker load < $image ; done
}

function load_images_all_details() {

# sudo docker load < $IMAGE_PATH/registry-2.tar

# sudo docker load < $IMAGE_PATH/exechealthz-amd64-1.1.tar
# sudo docker load < $IMAGE_PATH/kube2sky-1.14.tar
# sudo docker load < $IMAGE_PATH/kubedns-amd64-1.6.tar
# sudo docker load < $IMAGE_PATH/kube-dnsmasq-amd64-1.3.tar
# sudo docker load < $IMAGE_PATH/pause-2.0.tar

# sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.4.0-beta2.tar

# sudo docker load < $IMAGE_PATH/heapster-canary.tar
# sudo docker load < $IMAGE_PATH/heapster_grafana-v2.6.0-2.tar
# sudo docker load < $IMAGE_PATH/heapster_influxdb-v0.5.tar
echo
}

function load_images_basics() {
echo -n "load_images_basics"
  sudo /usr/local/bin/docker load < $IMAGE_PATH/pause-2.0.tar
  sudo /usr/local/bin/docker load < $IMAGE_PATH/pause-0.8.0.tar
echo " ... done"
}

function load_images_registry() {
echo -n "load_images_registry"
  sudo /usr/local/bin/docker load < $IMAGE_PATH/registry-2.tar
echo " ... done"
}

function load_images_dns() {
echo -n "load_images_dns"
 # sudo docker load < $IMAGE_PATH/etcd-amd64-2.2.1.tar
 # sudo docker load < $IMAGE_PATH/exechealthz-1.0.tar
 # sudo docker load < $IMAGE_PATH/exechealthz-amd64-1.0.tar
  sudo docker load < $IMAGE_PATH/exechealthz-amd64-1.1.tar
 # sudo docker load < $IMAGE_PATH/kube2sky-1.14.tar
 # sudo docker load < $IMAGE_PATH/kubedns-amd64-1.5.tar
  sudo docker load < $IMAGE_PATH/kubedns-amd64-1.6.tar
  sudo docker load < $IMAGE_PATH/kube-dnsmasq-amd64-1.3.tar
 #sudo docker load < $IMAGE_PATH/pause-2.0.tar
 # sudo docker load < $IMAGE_PATH/pause-amd64-3.0.tar
 # sudo docker load < $IMAGE_PATH/skydns-2015-10-13-8c72f8c.tar
echo " ... done"
}

function load_images_dashboard() {
echo -n "load_images_dashboard"
 # sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.0.0.tar
  sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.1.1.tar
 # sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.4.0-beta2.tar
echo " ... done"
}

function load_images_heapster() {
echo -n "load_images_heapster"
  sudo docker load < $IMAGE_PATH/heapster-canary.tar
  sudo docker load < $IMAGE_PATH/heapster_grafana-v2.6.0-2.tar
  sudo docker load < $IMAGE_PATH/heapster_influxdb-v0.5.tar
echo " ... done"
}

load_images_basics >& /tmp/log
load_images_registry >> /tmp/log 2>&1
