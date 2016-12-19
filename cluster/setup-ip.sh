#!/bin/bash

SCRIPT_ROOT=$(dirname "${BASH_SOURCE}")
DEPLOY_ENV_FILE=$SCRIPT_ROOT/deploy/deploy_env

for i in `seq $#`
do
  if [ $i -eq 1 ]; then
    user=$1
  elif [ $i -eq 2 ]; then
    roles="a"
  else
    roles=$roles" i"
  fi
done

NUM_NODES=$(($# -2))

sed -i "s/MASTER=.*/MASTER=\"$2\"/g" $DEPLOY_ENV_FILE
sed -i "s/NODES=.*/NODES=\"${*:3}\"/g" $DEPLOY_ENV_FILE
sed -i "s/nodes=.*/nodes=\"${*:2}\"/g" $DEPLOY_ENV_FILE
sed -i "s/roles=.*/roles=\"${roles}\"/g" $DEPLOY_ENV_FILE
sed -i "s/NUM_NODES=.*/NUM_NODES=\"${NUM_NODES}\"/g" $DEPLOY_ENV_FILE
sed -i "s/PACKAGE_PATH=.*/PACKAGE_PATH=\/home\/${user}\/dashboard_packages/g" $DEPLOY_ENV_FILE
