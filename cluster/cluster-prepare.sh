#!/bin/bash

set -x

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env 
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

function install_deps() {
##scp packages to remote servers
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}
  echo $nodeIP
  echo $PACKAGE_PATH

if ([ $1 == "add" ] && [ "${roles_array[${ii}]}" == "ai" -o "${roles_array[${ii}]}" == "i" ]) || [ $1 == "deploy" ]; then
  ssh $nodeIP "mkdir -p $PACKAGE_PATH" >& /dev/null
  ## do not copy kubernetes packages to nodes
  ls $INSTALL_ROOT/dashboard_packages/ | grep -v kubernetes | while read f; do scp -r $INSTALL_ROOT/dashboard_packages/$f $nodeIP:$PACKAGE_PATH/ >& /dev/null; done
  ## copy kubernets package to local admin node
  mkdir -p $PACKAGE_PATH >& /dev/null
  ## only copy kubernetes packages to admin node
  ## TODO: the PACKAGE_PATH must exists on admin node, e.g., /home/satoshi/dashboard_packages which implies the node has a user named satoshi
  cp -r $INSTALL_ROOT/dashboard_packages/kubernetes $PACKAGE_PATH/ >& /dev/null

  #scp -r $INSTALL_ROOT/dashboard_packages/ $nodeIP:$PACKAGE_PATH/ >& /dev/null
  scp -r $SCRIPT_PATH $nodeIP:$PACKAGE_PATH >& /dev/null
  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-system-hosts.sh && \
                install_system_hosts"

  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-system-deps.sh && \
                install_system_deps_dpkg"

  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-docker-deps.sh && \
                install_docker_deps_dpkg"

  ## mandatorily enter this branch
  if true; then
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      echo ai or i
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    source deploy-docker-images.sh && \
                    load_images_basics && \
                    load_images_registry"
      
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    source deploy-docker-registry.sh && \
                    install_docker_registry && \
                    push_image_to_registry hyperchain alpha"
    fi
  else
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo ai or a
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    source deploy-docker-images.sh && \
                    load_images_basics && \
                    load_images_registry && \
                    load_images_heapster && \
                    load_images_dns && \
                    load_images_dashboard"
    else
      echo i
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    source deploy-docker-images.sh && \
                    load_images_basics && \
                    load_images_registry && \
                    load_images_dns"
    fi
  fi
fi

  ((ii=ii+1))
done
}

function remove_deps() {
##scp packages to remote servers
local ii=0
for i in $nodes; do
  nodeIP=${i#*@}
  echo $nodeIP
  echo $PACKAGE_PATH

if ([ $1 == "remove" ] && [ "${roles_array[${ii}]}" == "i" ]) || [ $1 == "purge" ]; then

  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-docker-deps.sh && \
                uninstall_docker_deps_dpkg"
  
  ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source deploy-system-deps.sh && \
                uninstall_system_deps_dpkg"

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
         install_deps deploy >> ./log-prepare-deploy.txt 2>&1
        echo d
        ;;
    -a|--add)
         install_deps add >> ./log-prepare-add.txt 2>&1
        echo a
        ;;
    -r|--remove)
         remove_deps remove >> ./log-remove-remove.txt 2>&1
        echo r
        ;;
    -p|--purge)
         remove_deps purge >> ./log-remove-purge.txt 2>&1
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
