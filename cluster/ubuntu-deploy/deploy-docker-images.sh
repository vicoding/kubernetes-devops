#!/bin/bash

PACKAGE_PATH=${PACKAGE_PATH:-$HOME/dashboard_packages}

IMAGE_PATH=$PACKAGE_PATH/images

function load_images_all() {
  ls $IMAGE_PATH | while read image ; do sudo docker load < $image ; done
}

function load_images_all_details() {
## sudo docker load < $IMAGE_PATH/ubuntu-latest.tar

# sudo docker load < $IMAGE_PATH/registry-2.tar

## sudo docker load < $IMAGE_PATH/etcd-amd64-2.2.1.tar
## sudo docker load < $IMAGE_PATH/exechealthz-1.0.tar
## sudo docker load < $IMAGE_PATH/exechealthz-amd64-1.0.tar
# sudo docker load < $IMAGE_PATH/exechealthz-amd64-1.1.tar
# sudo docker load < $IMAGE_PATH/kube2sky-1.14.tar
## sudo docker load < $IMAGE_PATH/kubedns-amd64-1.5.tar
# sudo docker load < $IMAGE_PATH/kubedns-amd64-1.6.tar
# sudo docker load < $IMAGE_PATH/kube-dnsmasq-amd64-1.3.tar
# sudo docker load < $IMAGE_PATH/pause-2.0.tar
### sudo docker load < $IMAGE_PATH/pause-amd64-3.0.tar
### sudo docker load < $IMAGE_PATH/skydns-2015-10-13-8c72f8c.tar

## sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.0.0.tar
### sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.1.1.tar
# sudo docker load < $IMAGE_PATH/kubernetes-dashboard-amd64-v1.4.0-beta2.tar

# sudo docker load < $IMAGE_PATH/heapster-canary.tar
# sudo docker load < $IMAGE_PATH/heapster_grafana-v2.6.0-2.tar
# sudo docker load < $IMAGE_PATH/heapster_influxdb-v0.5.tar
echo
}

function load_images_basics() {
echo -n "load_images_basics"
  sudo docker load < $IMAGE_PATH/pause-2.0.tar
  # sudo docker load < $IMAGE_PATH/ubuntu-latest.tar
echo " ... done"
}

function load_images_registry() {
echo -n "load_images_registry"
  sudo docker load < $IMAGE_PATH/registry-2.tar
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
 ## move pause-2.0.tar to load_images_basics functions
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
