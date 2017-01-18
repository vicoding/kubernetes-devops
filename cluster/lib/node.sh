#!/bin/bash

set -e

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")
source $INSTALL_ROOT/../centos/util.sh

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/../$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

MASTER_IP=${MASTER#*@}

function add_master() {
  cd $INSTALL_ROOT/../centos && provision-master

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
  code=$(curl -X DELETE -I -m 10 -o /dev/null -s -w %{http_code} http://${LOCAL_MASTER_IP}:8080/api/v1/nodes/${LOCAL_NODE_IP})

  tear-down-master
}

function remove_node() {
  code=$(curl -X DELETE -I -m 10 -o /dev/null -s -w %{http_code} http://${LOCAL_MASTER_IP}:8080/api/v1/nodes/${LOCAL_NODE_IP})

  tear-down-node $LOCAL_NODE_IP
}

LOCAL_MASTER_IP=$2
LOCAL_NODE_IP=${3#*@}

while [ $# -gt 0 ]
do
  case $1 in
    -m|--master)
        add_master >> $INSTALL_ROOT/../log_node_add_master.log 2>&1
        break
        ;;
    -n|--node)
        add_node >> $INSTALL_ROOT/../log_node_add_node.log 2>&1
        break
        ;;
    -p|--purge)
        remove_master >> $INSTALL_ROOT/../log_node_remove_master.log 2>&1
        break
        ;;
    -r|--remove)
        remove_node >> $INSTALL_ROOT/../log_node_remove_node.log 2>&1
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
