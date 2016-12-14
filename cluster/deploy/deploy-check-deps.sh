#!/bin/bash

function check_deps() {
  PACKAGE_NAME=$1

  if [ x`dpkg -l | grep "\ \ $PACKAGE_NAME\ " | awk '{print $1}'` == "xii" ]; then
    echo yes
  else
    echo no
  fi
}
