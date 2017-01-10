#!/bin/bash
count=1
while [ $count -le 6 ] # splits 30 minutes across 6 files
do
  if [ $count -le 6 ]
  then
    FILETIME=$(date +"%Y%m%d-%H%M%S") #gives date in format YYYYMMDD-HHMMSS
    FILENAME="PC-"$FILETIME".pcap" #Sets filename
    tcpdump -Z root -w $FILENAME -G 300 -W 1 #Runs TCPDump as root captures 5 mins
  fi
  (( count++ ))
done

