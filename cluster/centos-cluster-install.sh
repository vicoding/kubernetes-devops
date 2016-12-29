#!/bin/bash

set -x

SSH_TIMEOUT=10

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")
source $INSTALL_ROOT/init-functions

NODE_SCRIPT=$INSTALL_ROOT/lib/node.sh

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

MASTER_IP=${MASTER#*@}

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

  bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-down.sh" || install_failure_handler_advanced $nodes $roles return

  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      sudo scp $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl $nodeIP:/usr/local/bin || install_failure_handler $nodeIP ${roles_array[${ii}]}; return
      break
    fi
    ((ii=ii+1))
  done

  source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-up.sh || install_failure_handler_advanced $nodes $roles; return
echo
}

function install_k8s_new_node() {
  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -n $MASTER_IP $nodeIP" || install_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi
  ((ii=ii+1))
  done
}

function install_k8s_remove_node() {
  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    if [ "$1" == "purge" ] && [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -p $MASTER_IP $nodeIP" || install_failure_handler $nodeIP ${roles_array[${ii}]}; return
    elif [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -r $MASTER_IP $nodeIP" || install_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi
  ((ii=ii+1))
  done
}

sed_config_default

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
        install_k8s_cluster >> $INSTALL_ROOT/log-install-deploy.txt
        ;;
    -a|--add)
        install_k8s_new_node >> $INSTALL_ROOT/log-install-add.txt
        ;;
    -r|--remove)
        install_k8s_remove_node remove >> $INSTALL_ROOT/log-remove-k8s-remove.txt 2>&1
        ;;
    -p|--purge)
        install_k8s_remove_node purge >> ./log-remove-k8s-purge.txt 2>&1
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
