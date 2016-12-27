#!/bin/bash

set -x

SSH_TIMEOUT=10

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

function sed_config_default() {
  if [ ! -f $INSTALL_ROOT/centos/config-default.sh.bak ]; then
    cp $INSTALL_ROOT/centos/config-default.sh{,.bak}
  else
    cp $INSTALL_ROOT/centos/config-default.sh{.bak,}
  fi

  sed -i "s/MASTER:\-.*/MASTER:\-\"${MASTER}\"}/g" $INSTALL_ROOT/centos/config-default.sh
  sed -i "s/NODES:\-.*/NODES:\-\"${NODES}\"}/g" $INSTALL_ROOT/centos/config-default.sh
  sed -i "s/NUM_NODES:\-.*/NUM_NODES:\-\"${NUM_NODES}\"}/g" $INSTALL_ROOT/centos/config-default.sh
  echo "export PACKAGE_PATH=\${PACKAGE_PATH:-\"$PACKAGE_PATH\"}" >> $INSTALL_ROOT/centos/config-default.sh

}

function install_k8s_cluster() {
  local ii=0

  bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-down.sh >> $INSTALL_ROOT/log-install-deploy.txt 2>&1"

  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      sudo scp $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl $nodeIP:/usr/local/bin
      break
    fi
    ((ii=ii+1))
  done

  source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-up.sh >> $INSTALL_ROOT/log-install-deploy.txt 2>&1
echo
}

function install_k8s_new_node() {

  set -x
  source $INSTALL_ROOT/centos/util.sh
  #echo $MASTER_IP

  local ii=0
  for i in $nodes; do
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      tear-down-node $i

      cd $INSTALL_ROOT && provision-node $i >> $INSTALL_ROOT/log-install-add.txt 2>&1
      #echo $i
    fi
  ((ii=ii+1))
  done
}

function install_k8s_remove_node() {
  SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -C"

  source $INSTALL_ROOT/centos/util.sh
  #echo $MASTER_IP
  MASTER_IP=${MASTER#*@}

  local ii=0
  for i in ${nodes}; do

    code=$(curl -X DELETE -I -m 10 -o /dev/null -s -w %{http_code} http://${MASTER_IP}:8080/api/v1/nodes/${i#*@})
    if [ $code != "200" ]; then
      echo "Stopping node ${i#*@} failed"
    fi

    if [ "$1" == "purge" ] && [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo "Cleaning on master ${i#*@}"
      ssh -o ConnectTimtout=$SSH_TIMEOUT $SSH_OPTS $i 'sudo systemctl status docker.service'
      tear-down-master
    elif [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      echo "Cleaning on node ${i#*@}"
      ssh -o ConnectTimtout=$SSH_TIMEOUT $SSH_OPTS $i 'sudo systemctl status docker.service'
      tear-down-node $i
    fi
    ((ii=ii+1))
  done
}

sed_config_default

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
         install_k8s_cluster
        echo d
        ;;
    -a|--add)
         install_k8s_new_node
        echo a
        ;;
    -r|--remove)
         install_k8s_remove_node remove >> $INSTALL_ROOT/log-remove-k8s-remove.txt 2>&1
        echo r
        ;;
    -p|--purge)
         install_k8s_remove_node purge >> ./log-remove-k8s-purge.txt 2>&1
        echo r
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
