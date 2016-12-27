#!/bin/bash

PACKAGE_PATH=${PACKAGE_PATH:-$HOME/dashboard_packages}
DOCKER_VERSION=${DOCKER_VERSION:-"1.9.1"}

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")
source $INSTALL_ROOT/deploy-check-deps.sh
  
function get_docker_deps_deb() {
:
}

function install_docker_deps_zypper() {
:
}

function install_docker_deps_rpm() {
:
}

function install_docker_deps_bin() {
  sudo cp ${PACKAGE_PATH}/docker/* /usr/local/bin
}

function uninstall_docker_deps() {
# sudo rm -rf /usr/local/bin/docker*
:
}
