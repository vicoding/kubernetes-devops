#!/bin/bash

set -x

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env 
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

function install_deps() {
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}
  echo $nodeIP
  echo $PACKAGE_PATH

if ([ $1 == "add" ] && [ "${roles_array[${ii}]}" == "ai" -o "${roles_array[${ii}]}" == "i" ]) || [ $1 == "deploy" ]; then

  if ([ $1 == "deploy" ] && [ "${roles_array[${ii}]}" == "ai" -o "${roles_array[${ii}]}" == "a" ]); then
    mkdir -p $PACKAGE_PATH >& /dev/null
    cp -r $INSTALL_ROOT/dashboard_packages/{kubernetes,docker}/ $PACKAGE_PATH >& /dev/null
    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl /usr/local/bin >& /dev/null
    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/serviceaccount.key /tmp >& /dev/null
    sudo mkdir ~/kube{,_temp}
    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/*tar* ~/kube/ >& /dev/null
    sudo cp -r $INSTALL_ROOT/easy-rsa-master ~/kube_temp/ >& /dev/null
    sudo mkdir /root/kube{,_temp}
    sudo cp -r $INSTALL_ROOT/dashboard_packages/kubernetes/*tar* /root/kube/ >& /dev/null
    sudo cp -r $INSTALL_ROOT/easy-rsa-master /root/kube_temp/ >& /dev/null
    #scp -r $INSTALL_ROOT/dashboard_packages/ $nodeIP:$PACKAGE_PATH/ >& /dev/null
    scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH >& /dev/null
  fi

  if [ "${roles_array[${ii}]}" == "ai" ] || [ "${roles_array[${ii}]}" == "i" ]; then
    ssh $nodeIP "mkdir -p $PACKAGE_PATH" >& /dev/null
    ls $INSTALL_ROOT/dashboard_packages/ | grep -v kubernetes | while read f; do scp -r $INSTALL_ROOT/dashboard_packages/$f $nodeIP:$PACKAGE_PATH/ >& /dev/null; done
    #scp -r $INSTALL_ROOT/dashboard_packages/ $nodeIP:$PACKAGE_PATH/ >& /dev/null
    scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH >& /dev/null
  fi


  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-system-hosts.sh && \
                install_system_hosts"

  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-docker-deps.sh && \
                install_docker_deps_bin"

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

  ((ii=ii+1))
done
}

function remove_deps() {
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}
  echo $nodeIP
  echo $PACKAGE_PATH

if ([ $1 == "remove" ] && [ "${roles_array[${ii}]}" == "i" ]) || [ $1 == "purge" ]; then

  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-docker-deps.sh && \
                uninstall_docker_deps"
  
  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-system-hosts.sh && \
                uninstall_system_hosts"

fi
done
}

#install_deps

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
         install_deps deploy >> $INSTALL_ROOT/log-prepare-deploy.txt 2>&1
        echo d
        ;;
    -a|--add)
         install_deps add >> $INSTALL_ROOT/log-prepare-add.txt 2>&1
        echo a
        ;;
    -r|--remove)
         remove_deps remove >> $INSTALL_ROOT/log-remove-remove.txt 2>&1
        echo r
        ;;
    -p|--purge)
         remove_deps purge >> $INSTALL_ROOT/log-remove-purge.txt 2>&1
        echo p
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
