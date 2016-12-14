#!/bin/bash

while true;
do
liveCmdStr="kubectl describe pods $name | grep '^.*Ready.*True.*$'"
diedCmdStr="kubectl describe pods $name | grep -i pending && kubectl describe pods $name | grep -i fail"

pods=(`kubectl get pods | grep -v NAME | awk '{print $1,$3}'`)
if [[ ${#pods[@]} -ne 0 ]]; then
  loop=$((${#pods[@]}/2-1))
  result="["
  for i in `seq 0 $loop`; do
    if [ $i -eq 0 ]; then
      result=$result"{\"name\":\"${pods[$i*2]}\",\"status\":\"${pods[$i*2+1]}\"}"
    else
      result=$result",{\"name\":\"${pods[$i*2]}\",\"status\":\"${pods[$i*2+1]}\"}"
    fi
  done
  result=$result"]"
  echo $loop
  echo $result
  #curl -H "Content-type:application/json" -H "Authorization:Basic ZXlKMGVYQWlPaUpLVjFRaUxDSmhiR2NpT2lKSVV6STFOaUo5LmV5SnBaQ0k2SWpVM1kySmpPV1V3TkdabE16bGhOV1V5WldNMFltSXpaQ0lzSW1WdFlXbHNJam9pWVdSdGFXNUFaWGhoYlhCc1pTNWpiMjBpTENKd1lYTnpkMjl5WkNJNkltaDVjR1Z5WTJoaGFXNGlMQ0psZUhBaU9qRTNPRGcxTWpRMk1qRXdNVFY5LnhBQVBsZmgwdEhGemdTdmRWdmQ0S2VnT2lxbWpJSWFoLVh6aHQ3Ym5KWEk6" -X PUT -d "$result" cn2.hyperchain.cn:2333/v1/chain/container/status/Listener
  curl -H "Content-type:application/json" -X PUT -d "$result" cn2.hyperchain.cn:2333/v1/container/status/Listener
fi

sleep 1
done
