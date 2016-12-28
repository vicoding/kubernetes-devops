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

function install_deps() {
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}

  if ([ $1 == "deploy" ] && [ "${roles_array[${ii}]}" == "ai" -o "${roles_array[${ii}]}" == "a" ]); then
    mkdir -p $PACKAGE_PATH
    cp -r $INSTALL_ROOT/dashboard_packages/{kubernetes,docker}/ $PACKAGE_PATH || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl /usr/local/bin || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/serviceaccount.key /tmp || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-system-hosts.sh -i" || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-docker-deps.sh -i" || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return

# if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
#   echo ai or i
#   ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
#                 source deploy-docker-images.sh && \
#                 load_images_basics && \
#                 load_images_registry"
#   
#   ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
#                 source deploy-docker-registry.sh && \
#                 install_docker_registry && \
#                 push_image_to_registry hyperchain alpha"
# fi
  fi

  if [ "${roles_array[${ii}]}" == "ai" ] || [ "${roles_array[${ii}]}" == "i" ]; then
    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "mkdir -p $PACKAGE_PATH" >& /dev/null || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    ls $INSTALL_ROOT/dashboard_packages/ | grep -v kubernetes | while read f; do scp -r $INSTALL_ROOT/dashboard_packages/$f $nodeIP:$PACKAGE_PATH/ >& /dev/null; done || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH >& /dev/null || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return

    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-system-hosts.sh -i" || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
    ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                  ./deploy-docker-deps.sh -i" || prepare_failure_handler $nodeIP ${roles_array[${ii}]}; return
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
                ./deploy-docker-deps.sh -r"
  ssh -o ConnectTimeout=$SSH_TIMEOUT $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                ./deploy-system-hosts.sh -r"

fi
done
}

#install_deps

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
        install_deps deploy >> $INSTALL_ROOT/log-prepare-deploy.txt 2>&1
        ;;
    -a|--add)
        install_deps add >> $INSTALL_ROOT/log-prepare-add.txt 2>&1
        ;;
    -r|--remove)
        remove_deps remove >> $INSTALL_ROOT/log-remove-remove.txt 2>&1
        ;;
    -p|--purge)
        remove_deps purge >> $INSTALL_ROOT/log-remove-purge.txt 2>&1
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
