#!/bin/bash

while true
do
cpu=`top -d 1 -n 2 -b | grep '^KiB Mem' | awk 'NR==2 {print $5/$3*100; exit}'`
mem=`top -d 1 -n 2 -b | grep '^.Cpu' | awk 'NR==2 {print 100-$8; exit}'`
echo "{\"cpu\":\"$cpu\",\"mem\":\"$mem\"}"
sleep 5
done
