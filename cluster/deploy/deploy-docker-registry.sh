#!/bin/bash

set -e

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
  
  ##original startup
  #echo "run registry and expose 5000 port"
  #sudo /usr/local/bin/docker stop registry && sudo /usr/local/bin/docker rm registry
  #sudo /usr/local/bin/docker run -d -p 5000:5000 --restart=always --name registry registry:${DOCKER_REGISTRY_VERSION}

  sudo mkdir -p /opt/data/registry/conf
  sudo cp $PACKAGE_PATH/docker-registry/* /opt/data/registry/conf
  sudo /usr/local/bin/docker run -d -p 5000:5000 -v /opt/data/registry:/tmp/registry-dev --restart=always --name registry registry:${DOCKER_REGISTRY_VERSION}
}

function push_image_to_registry() {
  IMAGE_NAME=$1
  IMAGE_VERSION=$2

  echo "load specified image - ${IMAGE_NAME}-${IMAGE_VERSION}.tar"
  #`sudo /usr/local/bin/docker images | grep ${IMAGE_NAME} | grep ${IMAGE_VERSION}`
  #if [ $? -ne 0 ]; then
    #sudo /usr/local/bin/docker stop $(/usr/local/bin/docker ps -qa) && sudo /usr/local/bin/docker rm $(/usr/local/bin/docker ps -qa)
    #sudo /usr/local/bin/docker rmi ${IMAGE_NAME}:${IMAGE_VERSION}
    sudo /usr/local/bin/docker load < ${IMAGE_PATH}/${IMAGE_NAME}-${IMAGE_VERSION}.tar
  #fi

  echo "tag it and push to registry"
  sudo /usr/local/bin/docker tag ${IMAGE_NAME}:${IMAGE_VERSION} docker.hyperchain.cn:5000/${IMAGE_NAME}-${IMAGE_VERSION}

  local counter=0
  sudo /usr/local/bin/docker push docker.hyperchain.cn:5000/${IMAGE_NAME}-${IMAGE_VERSION}
  while [ $? -ne 0 ]
  do
    ((counter=counter+1))
    if [ $counter -lt 2 ]; then
      echo "try again $counter"
      sudo /usr/local/bin/docker push docker.hyperchain.cn:5000/${IMAGE_NAME}-${IMAGE_VERSION}
    else
      echo "push image failed for $counter times"
      break
    fi
  done
}

function install_docker_registry_client() {
  sudo mkdir -p "/etc/docker/certs.d/docker.hyperchain.cn:5000"
  sudo cp $PACKAGE_PATH/docker-registry/docker-registry.crt /etc/docker/certs.d/docker.hyperchain.cn:5000/ca.crt
}

function uninstall_docker_image() {
  IMAGE_NAME=${1:-hyperchain}
  IMAGE_VERSION=${2:-1.1}

  sudo /usr/local/bin/docker rmi -f ${IMAGE_NAME}:${IMAGE_VERSION}
}

function uninstall_docker_registry() {
  #uninstall_docker_image hyperchain 1.1

  echo "stop and remove registry container"
  sudo /usr/local/bin/docker stop registry && sudo /usr/local/bin/docker rm -v registry

  #echo "remove registry image"
  #uninstall_docker_image docker.hyperchain.cn:5000 1.1
  #uninstall_docker_image hyperchain 1.1
  #uninstall_docker_image registry ${DOCKER_REGISTRY_VERSION}
  #uninstall_docker_image gcr.io/google_containers/pause ${PAUSE_VERSION}
}

while [ $# -gt 0 ]
do
  case $1 in
    -i|--install)
        install_docker_registry >> /tmp/log_docker_install_docker_registry.log 2>&1
        ;;
    -p|--push)
        push_image_to_registry hyperchain 1.1 >> /tmp/log_docker_push_image_to_registry.log 2>&1
        ;;
    -c|--client)
        install_docker_registry_client >> /tmp/log_docker_install_docker_registry_client.log 2>&1
        ;;
    -r|--remove)
        uninstall_docker_registry >> /tmp/log_docker_uninstall_docker_registry.log 2>&1
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
