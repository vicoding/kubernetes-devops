#!/bin/bash

set -x

SSH_TIMEOUT=10

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")
source $INSTALL_ROOT/init-functions

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env 
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

MASTER_IP=${MASTER#*@}


function install_deps() {
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}

  if ([ $1 == "deploy" -o $1 == "init" ] && [ "${roles_array[${ii}]}" == "ai" -o "${roles_array[${ii}]}" == "a" ]); then
    mkdir -p $PACKAGE_PATH

    cp -r $INSTALL_ROOT/dashboard_packages/{kubernetes,docker,images}/ $PACKAGE_PATH >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl /usr/local/bin >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/serviceaccount.key /tmp >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    cp -r $INSTALL_ROOT/docker-registry $PACKAGE_PATH >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "export MASTER_SERVER_IP=$MASTER_IP && \
                  cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-system-hosts.sh -i" >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-docker-deps.sh -i" >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    prepare_success_handler $nodeIP ${roles_array[${ii}]}
  fi

  if ([ $1 == "deploy" -o $1 == "add" ] && [ "${roles_array[${ii}]}" == "ai" -o "${roles_array[${ii}]}" == "i" ]); then
    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "mkdir -p $PACKAGE_PATH/images" >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    #ls $INSTALL_ROOT/dashboard_packages/ | grep -v kubernetes | while read f; do scp -r $INSTALL_ROOT/dashboard_packages/$f $nodeIP:$PACKAGE_PATH/ >& /dev/null; done >& /dev/null
    scp -r $INSTALL_ROOT/dashboard_packages/docker $nodeIP:$PACKAGE_PATH/ >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    scp -r $INSTALL_ROOT/dashboard_packages/images/pause-2.0.tar $nodeIP:$PACKAGE_PATH/images >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    scp -r $INSTALL_ROOT/docker-registry $nodeIP:$PACKAGE_PATH >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "export MASTER_SERVER_IP=$MASTER_IP && \
                  cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-system-hosts.sh -i" >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-docker-deps.sh -i" >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-docker-registry.sh -c" >& /dev/null
    if [ $? -ne 0 ]; then
      prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    fi
    prepare_success_handler $nodeIP ${roles_array[${ii}]}
  fi

  ((ii=ii+1))
done
}

function remove_deps() {
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}

if ([ $1 == "remove" ] && [ "${roles_array[${ii}]}" == "i" ]) || [ $1 == "purge" ]; then

  ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                ./deploy-docker-registry.sh -r"
  ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                ./deploy-docker-deps.sh -r"
  ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                ./deploy-system-hosts.sh -r"

# TODO: remove kubectl on KUBE_MASTER
fi
done
}

clean_report

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
        install_deps deploy >> $INSTALL_ROOT/log-prepare-deploy.txt 2>&1
        ;;
    -m|--master)
        install_deps init >> $INSTALL_ROOT/log-prepare-deploy.txt 2>&1
        ;;
    -a|--add)
        install_deps add >> $INSTALL_ROOT/log-prepare-add.txt 2>&1
        ;;
    -r|--remove)
        remove_deps remove >> $INSTALL_ROOT/log-remove-deps-remove.txt 2>&1
        ;;
    -p|--purge)
        remove_deps purge >> $INSTALL_ROOT/log-remove-deps-purge.txt 2>&1
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

prepare_failure_report
