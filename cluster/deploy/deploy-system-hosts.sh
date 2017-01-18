#!/bin/bash

set -e

MASTER_SERVER_IP=${MASTER_SERVER_IP:-"127.0.0.1"}

function install_system_hosts() {

  if [ ! -f /etc/host.gcr ]; then

    if [ ! -f /etc/hosts.bak ]; then 
      sudo cp /etc/hosts{,.bak}
    else
      sudo cp /etc/hosts{.bak,}
    fi

    sudo bash -c "cat << EOF >> /etc/hosts

# gcr
64.233.162.83   www.gcr.io gcr.io
64.233.162.83   https://gcr.io/
64.233.162.83   accounts.google.com
64.233.162.83   storage.googleapis.com

#docker-registry
$MASTER_SERVER_IP   docker.hyperchain.cn
EOF"

    sudo cp /etc/hosts{,.gcr}
  else
    sudo cp /etc/hosts{.gcr,}
  fi
}

function uninstall_system_hosts() {
  if [ -f /etc/hosts.gcr -a -f /etc/hosts.bak ]; then 
    sudo cp /etc/hosts{.bak,}
    sudo rm /etc/hosts.{gcr,bak}
  fi
}

while [ $# -gt 0 ]
do
  case $1 in
    -i|--install)
        install_system_hosts
        ;;
    -r|--remove)
        uninstall_system_hosts
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
