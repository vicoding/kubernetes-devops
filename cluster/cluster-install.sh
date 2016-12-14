#!/bin/bash

set -x

INSTALL_ROOT=$(dirname "${BASH_SOURCE}")

SCRIPT_DIRECTORY=deploy
SCRIPT_PATH=$INSTALL_ROOT/$SCRIPT_DIRECTORY
ENV_FILE_NAME=deploy_env
source $SCRIPT_PATH/$ENV_FILE_NAME
roles_array=($roles)

function sed_config_default() {
  if [ ! -f $INSTALL_ROOT/ubuntu/config-default.sh.bak ]; then
    cp $INSTALL_ROOT/ubuntu/config-default.sh{,.bak}
  else
    cp $INSTALL_ROOT/ubuntu/config-default.sh{.bak,}
  fi

  sed -i "s/nodes:\-.*/nodes:\-\"${nodes}\"}/g" $INSTALL_ROOT/ubuntu/config-default.sh
  sed -i "s/roles:\-.*/roles:\-\"${roles}\"}/g" $INSTALL_ROOT/ubuntu/config-default.sh
  sed -i "s/NUM_NODES:\-.*/NUM_NODES:\-\"${NUM_NODES}\"}/g" $INSTALL_ROOT/ubuntu/config-default.sh
}

function sed_download_release() {
  if [ ! -f $INSTALL_ROOT/ubuntu/download-release.sh.bak ]; then
    cp $INSTALL_ROOT/ubuntu/download-release.sh{,.bak}
  else
    cp $INSTALL_ROOT/ubuntu/download-release.sh{.bak,}
  fi

  sed -i "/set \-e/a PACKAGE_PATH=\${PACKAGE_PATH:-\$HOME/dashboard_packages}" $INSTALL_ROOT/ubuntu/download-release.sh

  sed -i "/curl.*coreos\/flannel.*/d " $INSTALL_ROOT/ubuntu/download-release.sh
  sed -i "/tar xzf flannel.*/a if [ ! -d flannel-\${FLANNEL_VERSION} ]; then\n if [ ! -f \${PACKAGE_PATH}/kubernetes/flannel-\${FLANNEL_VERSION}-linux-amd64.tar.gz ]; then\n curl -L  https://github.com/coreos/flannel/releases/download/v\${FLANNEL_VERSION}/flannel-\${FLANNEL_VERSION}-linux-amd64.tar.gz -o flannel.tar.gz\n else\n cp \${PACKAGE_PATH}/kubernetes/flannel-\${FLANNEL_VERSION}-linux-amd64.tar.gz flannel.tar.gz\n fi\n tar xzf flannel.tar.gz\n fi\n" $INSTALL_ROOT/ubuntu/download-release.sh
  sed -i "$!N;/\n.*if.*-d flannel-\${FLANNEL_VERSION}/!P;D" $INSTALL_ROOT/ubuntu/download-release.sh

  sed -i "/curl.*coreos\/etcd*/d " $INSTALL_ROOT/ubuntu/download-release.sh
  sed -i "/tar xzf etcd.*/a if [ ! -d \${ETCD} ]; then\n if [ ! -f \${PACKAGE_PATH}/kubernetes/\${ETCD}.tar.gz ]; then curl -L https://github.com/coreos/etcd/releases/download/v\${ETCD_VERSION}/\${ETCD}.tar.gz -o etcd.tar.gz\n else\n cp \${PACKAGE_PATH}/kubernetes/\${ETCD}.tar.gz etcd.tar.gz\n fi\n tar xzf etcd.tar.gz\n fi\n" $INSTALL_ROOT/ubuntu/download-release.sh
  sed -i "$!N;/\n.*if.*-d \${ETCD}/!P;D" $INSTALL_ROOT/ubuntu/download-release.sh

  sed -i "/curl.*download\/v\${KUBE_VERSION}.*/d " $INSTALL_ROOT/ubuntu/download-release.sh
  sed -i "/tar xzf kubernetes.tar.gz/a if [ ! -d kubernetes ]; then\n if [ ! -f \${PACKAGE_PATH}/kubernetes/kubernetes-v\${KUBE_VERSION}.tar.gz ]; then\n curl -L https://github.com/kubernetes/kubernetes/releases/download/v\${KUBE_VERSION}/kubernetes.tar.gz -o kubernetes.tar.gz\n else\n cp \${PACKAGE_PATH}/kubernetes/kubernetes-v\${KUBE_VERSION}.tar.gz kubernetes.tar.gz\n fi\n tar xzf kubernetes.tar.gz\n fi\n" $INSTALL_ROOT/ubuntu/download-release.sh
  sed -i "$!N;/\n.*if.*-d kubernetes/!P;D" $INSTALL_ROOT/ubuntu/download-release.sh

  sed -i "s/rm -rf flannel* kubernetes* etcd*\n/#rm -rf flannel* kubernetes* etcd*\n/g" $INSTALL_ROOT/ubuntu/download-release.sh
}

function sed_util() {
  if [ ! -f $INSTALL_ROOT/ubuntu/util.sh.bak ]; then
    cp $INSTALL_ROOT/ubuntu/util.sh{,.bak}
  else
    cp $INSTALL_ROOT/ubuntu/util.sh{.bak,}
  fi

  sed -i "/curl.*easy-rsa/a PACKAGE_PATH=\${PACKAGE_PATH:-\$HOME/dashboard_packages}\n if [ ! -f easy-rsa.tar.gz ]; then\n if [ ! -f \${PACKAGE_PATH}/kubernetes/easy-rsa.tar.gz ]; then\n curl -L -O https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz > /dev/null 2>&1\n else\n cp \${PACKAGE_PATH}/kubernetes/easy-rsa.tar.gz .\n fi\n fi\n" $INSTALL_ROOT/ubuntu/util.sh
  sed -i "$!N;/.?*PACKAGE_PATH=.*/!P;D" $INSTALL_ROOT/ubuntu/util.sh
}

function sed_reconfDocker() {
  if [ ! -f $INSTALL_ROOT/ubuntu/reconfDocker.sh.bak ]; then
    cp $INSTALL_ROOT/ubuntu/reconfDocker.sh{,.bak}
  else
    cp $INSTALL_ROOT/ubuntu/reconfDocker.sh{.bak,}
  fi

  sed -i "/source \/etc\/default\/docker/d" $INSTALL_ROOT/ubuntu/reconfDocker.sh
}

function install_k8s_cluster() {
  local ii=0

  for i in $nodes; do
    ssh $i "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
              source clean.sh && \
              clean"
  done

  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo "cp kubectl binary"
      scp $INSTALL_ROOT/dashboard_packages/kubernetes/kubectl $nodeIP:/usr/local/bin >& /dev/null
      break
    fi
    ((ii=ii+1))
  done

  bash -c "source $SCRIPT_PATH/$ENV_FILE_NAME && cd $INSTALL_ROOT && ./kube-up.sh >> ./log-install-deploy.txt 2>&1"
echo
}

function install_k8s_new_node() {
  KUBE_ROOT=$(dirname "${BASH_SOURCE}")/..
  export KUBE_CONFIG_FILE=${KUBE_CONFIG_FILE:-${KUBE_ROOT}/cluster/ubuntu/config-default.sh}
  source "${KUBE_CONFIG_FILE}"

  set -x
  source $INSTALL_ROOT/ubuntu/util.sh
  setClusterInfo
  #echo $MASTER_IP

  local ii=0
  for i in $nodes; do
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      ssh $i "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                source clean.sh && \
                clean"

      cd $INSTALL_ROOT && provision-node $i >> ./log-install-add.txt 2>&1
      #echo $i
    fi
  ((ii=ii+1))
  done
}

function install_k8s_remove_node() {
  SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR -C"

  source $INSTALL_ROOT/ubuntu/util.sh
  setClusterInfo
  #echo $MASTER_IP

  local ii=0
  for i in ${nodes}; do
:<<UNSUPPORTED
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo "Cleaning on master ${i#*@}"
      ssh $SSH_OPTS -t "$i" "
        pgrep etcd && \
        sudo -p '[sudo] password to stop master: ' -- /bin/bash -c '
          service etcd stop

          rm -rf \
            /opt/bin/etcd* \
            /etc/init/etcd.conf \
            /etc/init.d/etcd \
            /etc/default/etcd

          rm -rf /infra*
          rm -rf /srv/kubernetes
          '
      " || echo "Cleaning on master ${i#*@} failed"

      if [[ "${roles_array[${ii}]}" == "ai" ]]; then
        ssh $SSH_OPTS -t "$i" "sudo rm -rf /var/lib/kubelet"
      fi

    elif [[ "${roles_array[${ii}]}" == "i" ]]; then
      echo "Cleaning on node ${i#*@}"
      ssh $SSH_OPTS -t "$i" "
        pgrep flanneld && \
        sudo -p '[sudo] password to stop node: ' -- /bin/bash -c '
          service flanneld stop
          rm -rf /var/lib/kubelet
          '
        " || echo "Cleaning on node ${i#*@} failed"
    else
      echo "unsupported role for ${i}"
    fi

    ssh $SSH_OPTS -t "$i" "sudo -- /bin/bash -c '
      rm -f \
        /opt/bin/kube* \
        /opt/bin/flanneld \
        /etc/init/kube* \
        /etc/init/flanneld.conf \
        /etc/init.d/kube* \
        /etc/init.d/flanneld \
        /etc/default/kube* \
        /etc/default/flanneld

      rm -rf ~/kube
      rm -f /run/flannel/subnet.env
    '" || echo "cleaning legacy files on ${i#*@} failed"
    ((ii=ii+1))
UNSUPPORTED
set -x

    code=$(curl -X DELETE -I -m 10 -o /dev/null -s -w %{http_code} http://${MASTER_IP}:8080/api/v1/nodes/${i#*@})
    if [ $code != "200" ]; then
      echo "Stopping node ${i#*@} failed"
    fi
      
    ## the current version only supports the node deleting
    if [[ "${roles_array[${ii}]}" == "i" ]]; then
      echo "Cleaning on node ${i#*@}"
      ssh $SSH_OPTS -t "$i" "
        pgrep flanneld && \
        sudo -p '[sudo] password to stop node: ' -- /bin/bash -c '
          service flanneld stop
          rm -rf /var/lib/kubelet
          '
        " || echo "Cleaning on node ${i#*@} failed"

      ssh $SSH_OPTS -t "$i" "sudo -- /bin/bash -c '
        rm -f \
          /opt/bin/kube* \
          /opt/bin/flanneld \
          /etc/init/kube* \
          /etc/init/flanneld.conf \
          /etc/init.d/kube* \
          /etc/init.d/flanneld \
          /etc/default/kube* \
          /etc/default/flanneld

        rm -rf ~/kube
        rm -f /run/flannel/subnet.env
      '" || echo "cleaning legacy files on ${i#*@} failed"

    elif [[ $1 == "remove" ]] && [[ "${roles_array[${ii}]}" == "ai" ]]; then
      echo "Cleaning on node ${i#*@}"
      ssh $SSH_OPTS -t "$i" "
        pgrep flanneld && \
        sudo -p '[sudo] password to stop node: ' -- /bin/bash -c '
          service kubelet stop
          service kube-proxy stop
          rm -rf /var/lib/kubelet
          '
        " || echo "Cleaning on node ${i#*@} failed"

      ssh $SSH_OPTS -t "$i" "sudo -- /bin/bash -c '
        rm -f \
          /opt/bin/kube{let,-proxy} \
          /etc/init/kube{let,-proxy}.conf \
          /etc/init.d/kube{let,-proxy} \
          /etc/default/kube{let,-proxy}

        rm -rf \
          ~/kube/init_conf/kube{let,-proxy}.conf \
          ~/kube/init_scripts/kube{let,-proxy} \
          ~/kube/default/kube{let,-proxy} \
          ~/kube/minion
      '" || echo "cleaning legacy files on ${i#*@} failed"

      echo "Restarting flanneld on node ${i#*@}"
      ssh $SSH_OPTS -t "$i" "
        sudo -p '[sudo] password to stop node: ' -- /bin/bash -c '
          service flanneld restart
      '" || echo "restarting flanneld on ${i#*@} failed"


    elif [[ $1 == "purge" ]] && [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo "Cleaning on master ${i#*@}"
      ssh $SSH_OPTS -t "$i" "
        pgrep etcd && \
        sudo -p '[sudo] password to stop master: ' -- /bin/bash -c '
          service etcd stop

          rm -rf \
            /opt/bin/etcd* \
            /etc/init/etcd.conf \
            /etc/init.d/etcd \
            /etc/default/etcd

          rm -rf /infra*
          rm -rf /srv/kubernetes
          '
      " || echo "Cleaning on master ${i#*@} failed"

      if [[ "${roles_array[${ii}]}" == "ai" ]]; then
        ssh $SSH_OPTS -t "$i" "sudo rm -rf /var/lib/kubelet"
      fi

    else
      echo "unsupported role for ${i} ${roles_array[${ii}]}"
    fi
    ((ii=ii+1))
  done
}

function install_k8s_dns_dashboard() {
  ADDONS_SCRIPT_DIRECTORY=cluster
  ADDONS_SCRIPT_PATH=$SCRIPT_PATH/$ADDONS_SCRIPT_DIRECTORY

  if [ ! -d $ADDONS_SCRIPT_PATH ]; then
    mkdir -p $ADDONS_SCRIPT_PATH/{addons,skeleton,ubuntu}
    ## copy all scripts under ./cluster directory with depth=1
    cp $INSTALL_ROOT/*.sh $ADDONS_SCRIPT_PATH
    ## copy dns & dashboard directories
    cp -r $INSTALL_ROOT/addons/{dns,dashboard} $ADDONS_SCRIPT_PATH/addons
    ## copy all scripts under ./cluster/skeleton directory
    cp $INSTALL_ROOT/skeleton/* $ADDONS_SCRIPT_PATH/skeleton
    
    ## select some useful stuff under ./cluster/ubuntu directory
    ## copy all scripts under ./cluster/ubuntu directory with depth=1
    cp $INSTALL_ROOT/ubuntu/*.sh $ADDONS_SCRIPT_PATH/ubuntu
    ## copy kubectl binary under ./cluster/ubuntu/binaries directory
    mkdir -p $ADDONS_SCRIPT_PATH/ubuntu/binaries
    cp $INSTALL_ROOT/ubuntu/binaries/kubectl $ADDONS_SCRIPT_PATH/ubuntu/binaries
    ## copy namespace.yaml
    cp $INSTALL_ROOT/ubuntu/namespace.yaml $ADDONS_SCRIPT_PATH/ubuntu
  fi  

  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo ai or a $nodeIP
      scp -r $ADDONS_SCRIPT_PATH $nodeIP:$PACKAGE_PATH/$SCRIPT_DIRECTORY >& /dev/null
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    cd $ADDONS_SCRIPT_DIRECTORY/ubuntu && \
                    ./deployAddons.sh"
      break
    fi
    ((ii=ii+1))
  done
}

function install_k8s_heapster() {
  HEAPSTER_SCRIPT_DIRECTORY=heapster
  HEAPSTER_SCRIPT_PATH=$SCRIPT_PATH/$HEAPSTER_SCRIPT_DIRECTORY

  ## copy the origin files to script directory
  cp -r $INSTALL_ROOT/$HEAPSTER_SCRIPT_DIRECTORY $SCRIPT_PATH

  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "a" ]]; then
      echo ai or a $nodeIP

      ## sed heapster-controller.yaml
      sed -i "s/ imagePullPolicy/# imagePullPolicy/g" $HEAPSTER_SCRIPT_PATH/heapster-controller.yaml
      sed -i "s/kubernetes.default/$nodeIP:8080\?inClusterConfig=false\&useServiceAccount=false/g" $HEAPSTER_SCRIPT_PATH/heapster-controller.yaml
      sed -i "s/monitoring-influxdb/$nodeIP/g" $HEAPSTER_SCRIPT_PATH/heapster-controller.yaml

      ## sed influxdb-grafana-controller.yaml
      sed -i "/heapster_influxdb/a \ \ \ \ \ \ \ \ ports:\n        - containerPort: 8086\n          hostPort: 8086\n        - containerPort: 8083\n          hostPort: 8083" $HEAPSTER_SCRIPT_PATH/influxdb-grafana-controller.yaml
      sed -i "s/monitoring-influxdb/$nodeIP/g" $HEAPSTER_SCRIPT_PATH/influxdb-grafana-controller.yaml

      ## it may be wrong, we should expose host port 8086
      ## sed influxdb-service.yaml
      #sed -i "/targetPort: 8086/d " $HEAPSTER_SCRIPT_PATH/influxdb-service.yaml

      scp -r $HEAPSTER_SCRIPT_PATH $nodeIP:$PACKAGE_PATH/$SCRIPT_DIRECTORY >& /dev/null
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    kubectl create -f $HEAPSTER_SCRIPT_DIRECTORY"

      break
    fi
    ((ii=ii+1))
  done
}

function install_k8s_registry() {
  REGISTRY_IMAGE_NAME=$1
  REGISTRY_IMAGE_VERSION=$2

  local ii=0
  for i in $nodes; do
    nodeIP=${i#*@}
    if [[ "${roles_array[${ii}]}" == "ai" || "${roles_array[${ii}]}" == "i" ]]; then
      ssh $nodeIP "cd $PACKAGE_PATH/$SCRIPT_DIRECTORY && source $ENV_FILE_NAME && \
                    source deploy-docker-registry.sh && \
                    install_docker_registry && \
                    push_image_to_registry $REGISTRY_IMAGE_NAME $REGISTRY_IMAGE_VERSION"
    fi
  ((ii=ii+1))
  done
}

 sed_config_default
 sed_download_release
 sed_util
 sed_reconfDocker

#install_k8s_cluster
#install_k8s_new_node
#install_k8s_remove_node

#install_k8s_dns_dashboard
#install_k8s_heapster

#install_k8s_registry ubuntu latest

while [ $# -gt 0 ]
do
  case $1 in
    -d|--deploy)
         install_k8s_cluster
        echo d
        ;;
    -a|--add)
         install_k8s_new_node
        echo a
        ;;
    -r|--remove)
         install_k8s_remove_node remove >> ./log-remove-k8s-remove.txt 2>&1
        echo r
        ;;
    -p|--purge)
         install_k8s_remove_node purge >> ./log-remove-k8s-purge.txt 2>&1
        echo r
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
