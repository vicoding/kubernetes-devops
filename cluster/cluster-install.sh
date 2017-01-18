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

  bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-down.sh" >& /dev/null
  if [ $? -ne 0 ]; then
    install_failure_handler_advanced $nodes $roles return
  fi

  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      sudo scp $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl $nodeIP:/usr/local/bin >& /dev/null
      if [ $? -ne 0 ]; then
        install_failure_handler_advanced $nodes $roles return
      fi
      break
    fi
    ((ii=ii+1))
  done

  source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-up.sh
#  result=$(source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-up.sh >& /dev/null)
#  if [ $result -ne 0 ]; then
#    install_failure_handler_advanced $nodes $roles return
#  fi
echo
}

function install_k8s_init_master() {
  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    check_prepare_report $nodeIP
    if [ $? -eq 0 ]; then
      if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
        bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -m $MASTER_IP $nodeIP" >& /dev/null 
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi
        sleep 3

        ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                      ./deploy-docker-images.sh -b" >& /dev/null
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi

        ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                      ./deploy-docker-images.sh -r" >& /dev/null
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi

        ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                      ./deploy-docker-registry.sh -i" >& /dev/null
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi

        ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                      ./deploy-docker-registry.sh -p" >& /dev/null
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi
      fi
    else
      install_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi
  ((ii=ii+1))
  done
}

function install_k8s_new_node() {
  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    check_prepare_report $nodeIP
    if [ $? -eq 0 ]; then
      if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
        bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -n $MASTER_IP $nodeIP" >& /dev/null 
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi

        ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                      ./deploy-docker-images.sh -b" >& /dev/null
        if [ $? -ne 0 ]; then
          install_failure_handler $nodeIP ${roles_array[${ii}]}; return
        fi
      fi
    else
      install_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi
  ((ii=ii+1))
  done
}

function install_k8s_remove_node() {
  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    if [ "$1" == "purge" ] && [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -p $MASTER_IP $nodeIP" >& /dev/null
    elif [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT/lib && ./node.sh -r $MASTER_IP $nodeIP" >& /dev/null
    fi
  ((ii=ii+1))
  done
}

function install_k8s_purge_node() {
  bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-down.sh" >& /dev/null
}

sed_config_default

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
        install_k8s_cluster >> $INSTALL_ROOT/log-install-deploy.txt 2>&1
        ;;
    -m|--master)
        install_k8s_init_master >> $INSTALL_ROOT/log-install-init.txt 2>&1
        ;;
    -a|--add)
        install_k8s_new_node >> $INSTALL_ROOT/log-install-add.txt 2>&1
        ;;
    -r|--remove)
        install_k8s_remove_node remove >> $INSTALL_ROOT/log-remove-k8s-remove.txt 2>&1
        ;;
    -p|--purge)
        install_k8s_purge_node >> $INSTALL_ROOT/log-remove-k8s-purge.txt 2>&1
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

install_failure_report
generate_report
