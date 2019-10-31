#!/bin/bash
poorguy=$1

echo "Who are we looking for? IP address please!" ; echo ; for AP_TO_CONNECT_TO in `grep ap /etc/hosts | awk {'print $2'}` ; do echo "Looking for ${poorguy} on ${AP_TO_CONNECT_TO}" ; echo "The poor guy MAC address is :" ; echo ; arp -a | grep ${poorguy} | awk {'print $4'} ; MAC_OF_THE_HACKER=$(arp -a | grep ${poorguy} | awk {'print $4'}) ; ssh -q -o BatchMode=yes ${AP_TO_CONNECT_TO} 'iw dev wlan0 station dump ; iw dev wlan1 station dump' | grep Station  | grep ${MAC_OF_THE_HACKER}  && echo "FOUND AT ${AP_TO_CONNECT_TO}" ; done | grep FOUND
