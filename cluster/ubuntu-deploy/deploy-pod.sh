#!/bin/bash

set -x

function generate_rc() {
  RC_NAME=$1
  RC_PREFIX=$2
  RC_IP=$3
  RC_PORT=$4

  RC_CPU=${5:-1}
  RC_MEM=${6:-500Mi}

  > /root/pod_rc/${RC_NAME}-rc.yaml

  cat << EOF >> /root/pod_rc/${RC_NAME}-rc.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: ${RC_NAME}-rc
  labels:
    app: ${RC_NAME}
    version: v1
spec:
  replicas: 1
  selector:
    app: ${RC_NAME}
    version: v1
  template:
    metadata:
      labels:
        app: ${RC_NAME}
        version: v1
    spec:
      containers:
      - image: localhost:5000/ubuntu
        name: ${RC_NAME}
        tty: true
        stdin: true
        command: ["/bin/bash"]
        ports:
        # All http services
        - containerPort: ${RC_PORT}
          hostPort: ${RC_PORT}
          protocol: TCP
      nodeSelector:
        kubernetes.io/hostname: ${RC_IP}
EOF
}

function create_pod() {
  POD_NAME=$1
  POD_PREFIX=$2
  POD_IP=$3
  POD_PORT=$4
  POD_CPU=$5
  POD_MEM=$6
  CURL_PORT=$7
  POD_ID=$8

  mkdir -p /root/pod_rc
# ssh cn3 "mkdir -p /root/pod_rc" >& /dev/null
  generate_rc $POD_NAME $POD_PREFIX $POD_IP $POD_PORT
# scp /root/pod_rc/${POD_NAME}-rc.yaml cn3:/root/pod_rc/
# ssh cn3 "kubectl create -f /root/pod_rc/${POD_NAME}-rc.yaml"
  kubectl create -f /root/pod_rc/${POD_NAME}-rc.yaml
  result=$?
  if [ $result -eq 0 ]; then
    while true
    do
      #containerId=`ssh cn3 "kubectl describe pods ${POD_NAME}-rc | grep \"Container ID\" | sed 's,.*docker:\/\/,,g'"`
      containerId=`kubectl describe pods ${POD_NAME}-rc | grep "Container ID" | sed 's,.*docker://,,g'`
      echo $containerId | grep "Container"
      if [ $? -eq 0 ]; then
        continue
      else
        break
      fi
    done
    curl -H "Content-type:application/json" -X POST -d "{\"state\":$result,\"id\":\"${POD_ID}\",\"containerId\":\"${containerId}\"}" http://localhost:${CURL_PORT}/v1/container/state
  else
    #kubectl delete rc ${POD_NAME}-rc
    echo $result > /root/pod_rc/result-${POD_NAME}
    curl -H "Content-type:application/json" -X POST -d "{\"state\":$result,\"id\":\"${POD_ID}\",\"containerId\":\"\"}" http://localhost:${CURL_PORT}/v1/container/state
  fi
}

function get_pod() {
:
}

function test() {
  echo
  result=$?
  POD_NAME=ubuntu1
  containerId=`ssh cn3 "kubectl describe pods ${POD_NAME}-rc | grep \"Container ID\" | sed 's,.*\/,,g'"`
  curl -H "Content-type:application/json" -X POST -d "{\"state\":\"$result\",\"name\":\"$POD_NAME\",\"id\":\"$containerId\"}" http://localhost:2333/v1/container/state
}

create_pod $1 $2 $3 $4 $5 $6 $7 $8
#test
