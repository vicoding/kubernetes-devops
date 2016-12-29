#!/bin/bash

set -e

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")
source $INSTALL_ROOT/../centos/util.sh

TT=$(dirname "${BASH_SOURCE}")

function add_master() {
  cd $INSTALL_ROOT && provision-master

:<<DISABLE
  detect-master

  # set CONTEXT and KUBE_SERVER values for create-kubeconfig() and get-password()
  export CONTEXT="centos"
  export KUBE_SERVER="http://${KUBE_MASTER_IP}:8080"
  source "${KUBE_ROOT}/cluster/common.sh"

  # set kubernetes user and password
  get-password
  create-kubeconfig
DISABLE
}

function add_node() {
  cd $INSTALL_ROOT && provision-node $LOCAL_NODE_IP
}

function remove_master() {
  ssh -o ConnectTimtout=$SSH_TIMEOUT $SSH_OPTS $i 'sudo systemctl status docker.service'

  code=$(curl -X DELETE -I -m 10 -o /dev/null -s -w %{http_code} http://${LOCAL_MASTER_IP}:8080/api/v1/nodes/${LOCAL_NODE_IP})

  ssh -o ConnectTimtout=$SSH_TIMEOUT $SSH_OPTS $i 'sudo systemctl status docker.service'
  tear-down-master
}

function remove_node() {
  SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -C"

  code=$(curl -X DELETE -I -m 10 -o /dev/null -s -w %{http_code} http://${LOCAL_MASTER_IP}:8080/api/v1/nodes/${LOCAL_NODE_IP})

  ssh -o ConnectTimtout=$SSH_TIMEOUT $SSH_OPTS $i 'sudo systemctl status docker.service'
  tear-down-node $LOCAL_NODE_IP
}

LOCAL_MASTER_IP=$2
LOCAL_NODE_IP=${3#*@}

while [ $# -gt 0 ]
do
  case $1 in
    -m|--master)
        add_master
        break
        ;;
    -n|--node)
        add_node
        break
        ;;
    -p|--purge)
        remove_master
        break
        ;;
    -r|--remove)
        remove_node
        break
        ;;
    --)
        break
        ;;
    *)
        echo "unsupported option"
        break
        ;;
  esac
  shift
done
