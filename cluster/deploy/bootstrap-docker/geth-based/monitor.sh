#!/bin/bash

LOCAL_CONFIG_PATH=$1
TYPE=$2

while true
do
  pid=`ps aux | grep "geth" | grep -v grep | awk '{print $2}'`;
  if [ x"$pid" = x ]; then
    echo no pid
    nohup bash $LOCAL_CONFIG_PATH/startup-geth.sh >& /root/geth.log &
    pm2 start /root/ether-stats-client/processes.json

    if [ "$TYPE" = "ledger" ]; then
      echo 'miner.start()' | geth attach
    fi
  else
    echo geth is still alive
    echo config $LOCAL_CONFIG_PATH
    sleep 1
    continue
  fi
done
