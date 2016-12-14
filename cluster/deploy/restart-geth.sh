#!/bin/bash

target='bash.*test.sh'
geth_config_path="$HOME/setup"
geth_datadir="$HOME/.ethereum"

function kill_geth() {
  echo before
  ps aux | grep "$target" | grep -v grep | awk '{print $2}'
  echo kill 
  ps aux | grep "$target" | grep -v grep | awk '{print $2}' | xargs kill -9
  echo after
  ps aux | grep "$target" | grep -v grep | awk '{print $2}'
}

function start_geth() {
  echo recreate
  nohup bash test.sh &
  ps aux | grep "$target" | grep -v grep | awk '{print $2}'
}

function clean_env() {
  rm -rf $geth_datadir/{chaindata,dapp}
}
