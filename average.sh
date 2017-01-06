#!/bin/bash
awk '{print $6}' /logs/scripts/stat01_$HOSTNAME.log > /tmp/idle.txt  
awk '
 {s+=$0}
 END {printf "Sum =%10.2f,Avg = %10.2f\n",s,s/NR}
' /tmp/idle.txt
