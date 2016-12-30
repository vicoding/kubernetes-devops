#!/bin/bash

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")

if [ -f $INSTALL_ROOT/deploy_env ]; then
  source $INSTALL_ROOT/deploy_env
fi

if [ -f $INSTALL_ROOT/config-default.sh ]; then
  source $INSTALL_ROOT/config-default.sh
fi

PACKAGE_PATH=${PACKAGE_PATH:-$HOME/dashboard_packages}

IMAGE_PATH=$PACKAGE_PATH/images

DOCKER_REGISTRY_VERSION=${DOCKER_REGISTRY_VERSION:-2}

function install_docker_registry() {
  echo "load registry image"
#  sudo docker load < ${IMAGE_PATH}/registry-${DOCKER_REGISTRY_VERSION}.tar >& /dev/null
  
  echo "run registry and expose 5000 port"
  sudo /usr/local/bin/docker stop registry && sudo /usr/local/bin/docker rm registry
  sudo /usr/local/bin/docker run -d -p 5000:5000 --restart=always --name registry registry:${DOCKER_REGISTRY_VERSION}
}

function push_image_to_registry() {
  IMAGE_NAME=$1
  IMAGE_VERSION=$2

  echo "load specified image - ${IMAGE_NAME}-${IMAGE_VERSION}.tar"
  `sudo /usr/local/bin/docker images | grep ${IMAGE_NAME} | grep ${IMAGE_VERSION}`
  if [ $? -ne 0 ]; then
  #sudo /usr/local/bin/docker stop $(/usr/local/bin/docker ps -qa) && sudo /usr/local/bin/docker rm $(/usr/local/bin/docker ps -qa)
  #sudo /usr/local/bin/docker rmi ${IMAGE_NAME}:${IMAGE_VERSION}
  sudo /usr/local/bin/docker load < ${IMAGE_PATH}/${IMAGE_NAME}-${IMAGE_VERSION}.tar
  fi

# echo "tag it and push to registry"
# sudo /usr/local/bin/docker tag ${IMAGE_NAME}:${IMAGE_VERSION} localhost:5000/${IMAGE_NAME}-${IMAGE_VERSION}

# local counter=0
# sudo /usr/local/bin/docker push localhost:5000/${IMAGE_NAME}-${IMAGE_VERSION}
# while [ $? -ne 0 ]
# do
#   ((counter=counter+1))
#   if [ $counter -lt 2 ]; then
#     echo "try again $counter"
#     sudo /usr/local/bin/docker push localhost:5000/${IMAGE_NAME}-${IMAGE_VERSION}
#   else
#     echo "push image failed for $counter times"
#     break
#   fi
# done
}

function uninstall_docker_registry() {
  echo "stop and remove registry container"
  sudo /usr/local/bin/docker stop registry && sudo /usr/local/bin/docker rm -v registry

  echo "remove registry image"
  sudo /usr/local/bin/docker rmi register:${DOCKER_REGISTRY_VERSION}
}

push_image_to_registry hyperchain 1.1 >> /tmp/log 2>&1
install_docker_registry >> /tmp/log 2>&1
