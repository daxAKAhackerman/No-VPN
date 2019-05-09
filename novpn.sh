#!/bin/bash

# You can chose any number and routing table name (or leave it as default)
tableNumber=200
tableName="novpn"

# Define your default gateway (not the VPN one)
defaultGW="192.168.5.1"

# Define the ports you want to exclude from VPN (coma separated)
ports="22,21"

grep $tableName /etc/iproute2/rt_tables > /dev/null 2>&1

if [ $? -eq 1 ]; then
   echo "$tableNumber $tableName" >> /etc/iproute2/rt_tables
fi
   
if [ "$EUID" -ne 0 ]; then
   echo
   echo "=== Please run this program as root ==="
   echo
   exit
fi

if [ "$1" == "enable" ]; then

   if [[ $(ip route show table $tableNumber) ]]; then
      echo
      echo "=== You already ran the script ==="
      echo
   else
      iptables -t mangle -I OUTPUT -p tcp --match multiport --sport $ports -j MARK --set-mark 1
      ip rule add from all fwmark 0x1 table $tableName
	  
	  # You can also add static routes to your table if you need it
      #ip route add 192.168.5.0/24 dev eth0 table $tableName
      #ip route add 192.168.4.0/24 dev eth0 via 192.168.5.1 table $tableName

      ip route add default dev eth0 via $defaultGW table $tableName
      echo
      echo "=== Applied successfully ==="
      echo
   fi

elif [ "$1" == "disable" ]; then
   ip route del default dev eth0 via $defaultGW table $tableName
   
   # Be sure to deletes the routes if you added any
   #ip route del 192.168.4.0/24 dev eth0 via 192.168.5.1 table $tableName
   #ip route del 192.168.5.0/24 dev eth0 table $tableName
   
   ip rule del from all fwmark 0x1 table $tableName
   iptables -t mangle -D OUTPUT -p tcp --match multiport --sport $ports -j MARK --set-mark 1
   echo
   echo "=== Rules deleted ==="
   echo

else
   echo
   echo "Command usage: novpn [enable|disable]"
   echo
fi