#!/bin/sh
if [ `ifconfig | grep bond0 | awk '{print $1}'` ]
then
IP_ADDR=`ifconfig bond0 | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}'`
else
IP_ADDR=`ifconfig eth0 | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}'`
fi
echo Location: http://${IP_ADDR}:32400/web
echo ""
exit 0
