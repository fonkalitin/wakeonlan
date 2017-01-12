#!/bin/bash

# Wolmonitor ver. 0.8 (01.2017)
# By Goodinov A.V.
# This is the programm for monitoring ethernet traffic and do "wake on lan" (WOL) for some Host.

# Programm arguments
DUMPARG=`echo $1`

# Configuration variables:
CHECKTIME='5s' # Delay time for main cycle
PCOUNT="5" # Count of dumping packets
ETHINT1="br0" # Ethernet interface first - LAN+WLAN
ETHINT2="tun1" # Ethernet interface 3 - OPENVPN
ETHINT3="eth3" # Ethernet interface 2 # Router WAN Port
MACAD="xx:xx:xx:xx:xx:xx" # MAC address for WOL magic packet
DSTIP1="192.168.1.2" # Destenation IP address for dumping packets
DSTIP2="192.168.0.2" # Router WAN port

# Filters configuration for tcpdump:
DUMPFILT_LAN="(tcp dst port 445 or dst portrange 137-139 or tcp dst portrange 5900-5910 or dst portrange 20-23 or tcp dst port 80 or tcp dst p$
DUMPFILT_WAN="(tcp dst port 8000 or tcp dst port 9091)"

# --- Function that monitoring the traffic and if get "$PCOUNT" packets do wake on lan for host with "$MACAD"
TCPDUMP_FUNC()
{
if [ $1 = "DUMP1" ]
then
DUMP=`tcpdump -i $ETHINT1 -c $PCOUNT -ntq dst $DSTIP1 and $DUMPFILT_LAN` # LAN+WLAN
elif [ $1 = "DUMP2" ]
then
DUMP=`tcpdump -i $ETHINT2 -c $PCOUNT -ntq dst $DSTIP1 and $DUMPFILT_LAN` # OPENVPN
elif [ $1 = "DUMP3" ]
# Wolmonitor ver. 0.8 (01.2017)
# By Goodinov A.V.
# This is the programm for monitoring ethernet traffic and do "wake on lan" (WOL) for some Host.
then
DUMP=`tcpdump -i $ETHINT3 -c $PCOUNT -ntq dst $DSTIP2 and $DUMPFILT_WAN` # WAN
fi

if [ -n "$DUMP" ] # If string not null (get a filtered packets)
    then ether-wake -i $ETHINT1 $MACAD # Do the WOL
    else echo "WARNING: ERROR! There is some errors in 'tcpdump' or 'ether-wake' programm."
    break
    exit 3
fi
}

# ------ Main cycle -----
SNIF_CYCLE()
{
    while true ; do # Simple loop-cycle
    PING=`ping -I $ETHINT1 -s 1 -c 3 -W 2 $DSTIP1 | grep "100% packet loss"` # $
        if [ -n "$PING" ] # If string is not null (Host is sleeping)
        then
        TCPDUMP_FUNC $DUMPARG  # Start dumping packets
        echo "Ping is null. I get packets! WOL Magic Packet send ok!"
        else echo "Ping is OK. Host don't sleep." #>> /dev/null
        fi

    sleep $CHECKTIME # Pause looping. Waiting for "Checktime"
    echo "Check again..."
    done

exit 0
}

SNIF_CYCLE
