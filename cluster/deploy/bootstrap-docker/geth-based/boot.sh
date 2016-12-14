#!/bin/bash

SERVER=$1
#SERVER="10.175.198.30"

TYPE=$2
#TYPE=api
#TYPE=ledger
#TYPE=observer

POD_NAME=$3

IP=`ifconfig eth0 | grep 'inet addr' | awk '{print $2}' | sed 's/addr://g'`
REMOTE_CONFIG_PATH=/root/dashboard/public/confiles
LOCAL_CONFIG_PATH=$HOME/setup
ENODE_PATH=/root/dashboard/public/enode

## copy startup script and genesis config
mkdir -p $LOCAL_CONFIG_PATH
rm -rf $LOCAL_CONFIG_PATH/*
scp $SERVER:$REMOTE_CONFIG_PATH/startup-$TYPE.sh $LOCAL_CONFIG_PATH/startup-geth.sh
scp $SERVER:$REMOTE_CONFIG_PATH/genesis.json $LOCAL_CONFIG_PATH
ssh $SERVER "mkdir -p $ENODE_PATH"

function get_enode() {
  while true;
  do
    if [ -e ~/.ethereum/geth.ipc ]; then
      echo admin.nodeInfo | geth attach >& /dev/null
      result=$?
      if [ $result -eq 0 ]; then
        enode=$(enode_orig=`echo admin.nodeInfo | geth attach` && enode_no_suffix=${enode_orig%*?discport*} && enode_no_prefix_suffix=${enode_no_suffix#*enode:\ \"} && ip=`ifconfig eth0 | grep 'inet addr' | awk '{print $2}' | sed 's/addr://g'` && echo $enode_no_prefix_suffix | sed "s,\[::\],$ip,g")
	if [ x"$enode" = x ]; then
          ## wait until geth stared
          continue
        fi
      else
        ## wait until geth stared
        continue
      fi

      ## break after enode fetched
      break
    fi
  done
  echo $enode
}

function check_enode_and_start_geth() {
  local SERVER=$1
  local TYPE=$2
  local IP=$3
  local REMOTE_CONFIG_PATH=$4
  local LOCAL_CONFIG_PATH=$5
  local ENODE_PATH=$6
  
  while true
  do
    if [ `ssh $SERVER "ls $ENODE_PATH/enode_* | grep -v enode_$IP | wc -l" 2> /dev/null` -eq 0 ]; then
      echo "no enode info exists"
      sleep 1
    
      pid=`ps aux | grep "geth" | grep -v grep | awk '{print $2}'`;
      if [ x"$pid" = x ]; then
        echo no pid
        nohup bash $LOCAL_CONFIG_PATH/startup-geth.sh >& /root/geth.log &
      fi
    
      echo $(get_enode) > /tmp/enode_$IP
      scp /tmp/enode_$IP $SERVER:$ENODE_PATH
    
    else
      echo "more than one enode info exists"
    
      `ps aux | grep "geth" | grep -v grep | awk '{print $2}' | xargs kill -9 >& /dev/null`
      pid=`ps aux | grep "geth" | grep -v grep | awk '{print $2}'`
      if [ x"$pid" != x ]; then
        echo geth still alive
        ## wait until geth killed
        continue
      fi
    
      ## generate static-nodes.json
      ssh $SERVER 'prefix="enode"; directory=/root/dashboard/public/enode; cd $directory; test=`ls $prefix* >& /dev/null` && if [ $? -eq 0 ]; then enode_list=(`ls $prefix*`) && loop=$((${#enode_list[@]}-1)) && result="[" && for i in `seq 0 $loop`; do if [ $i -eq 0 ]; then result=$result"\"`cat ${enode_list[$i]}`\""; else result=$result",\"`cat ${enode_list[$i]}`\""; fi ; done; result=$result"]" && echo $result; else echo ; fi' > /tmp/static_$IP
      cp /tmp/static_$IP $HOME/.ethereum/static-nodes.json
    
      nohup bash $LOCAL_CONFIG_PATH/startup-geth.sh >& /root/geth.log &
    
      echo $(get_enode) > /tmp/enode_$IP
      scp /tmp/enode_$IP $SERVER:$ENODE_PATH
    
      break
    fi
  done
}

function generate_stats_client_json() {

  JSON_PATH=$1
  INSTANCE_NAME=$2
  
  > $JSON_PATH/processes.json

  cat << EOF >> $JSON_PATH/processes.json
[
  { 
    "name"              : "ether-stats-client",
    "cwd"               : "/root/ether-stats-client/",
    "script"            : "app.js",
    "log_date_format"   : "YYYY-MM-DD HH:mm Z",
    "log_file"          : "/root/ether-stats-client/logs/node-app-log.log",
    "out_file"          : "/root/ether-stats-client/logs/node-app-out.log",
    "error_file"        : "/root/ether-stats-client/logs/node-app-err.log",
    "merge_logs"        : true,
    "watch"             : false,
    "max_restarts"      : 10,
    "exec_interpreter"  : "node",
    "exec_mode"         : "fork_mode",
    "env":
    { 
      "NODE_ENV"        : "production",
      "RPC_HOST"        : "localhost",
      "RPC_PORT"        : "8545",
      "LISTENING_PORT"  : "30303",
      "INSTANCE_NAME"   : "$INSTANCE_NAME",
      "CONTACT_DETAILS" : "hyperchain",
      "WS_SERVER"       : "http://10.175.198.30:3000",
      "WS_SECRET"       : "kscc",
      "VERBOSITY"       : 2
    }
  }
]
EOF
}
 
function startup_stats_client() {
  pm2 start /root/ether-stats-client/processes.json
}

check_enode_and_start_geth $SERVER $TYPE $IP $REMOTE_CONFIG_PATH $LOCAL_CONFIG_PATH $ENODE_PATH

generate_stats_client_json /root/ether-stats-client $POD_NAME
startup_stats_client

if [ "$TYPE" = "ledger" ]; then
  echo 'miner.start()' | geth attach
fi

nohup bash /root/monitor.sh $LOCAL_CONFIG_PATH $TYPE &

/bin/bash
