#!/bin/bash

set -e

PACKAGE_PATH=${PACKAGE_PATH:-$HOME/dashboard_packages}
DOCKER_VERSION=${DOCKER_VERSION:-"1.12.3"}

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")
source $INSTALL_ROOT/deploy-check-deps.sh
  
function install_docker_deps_zypper() {
:
}

function install_docker_deps_rpm() {
:
}

function install_docker_deps_bin() {
  sudo cp ${PACKAGE_PATH}/docker/* /usr/local/bin
}

function uninstall_docker_deps_bin() {
  sudo rm -rf /usr/local/bin/docker*
  sudo rm -rf /var/lib/docker
}

while [ $# -gt 0 ]
do
  case $1 in
    -i|--install)
        install_docker_deps_bin
        ;;
    -r|--remove)
        uninstall_docker_deps_bin
        ;;
    -p|--pkg)
        install_docker_deps_rpm
        ;;
    -n|--network)
        install_docker_deps_zypper
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
