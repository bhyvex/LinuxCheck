#!/bin/bash 
# -*- coding: utf-8 -*-
#
#  linuxcheck.sh
#  
#  Copyright 2016 Hazem Hemied <hazem.hemied@gmail.com>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  

function sysstat {
echo -e "
#####################################################################
    Health Check Report (CPU,Process,Disk Usage, Memory)
#####################################################################


Hostname              : `hostname`
IPs		      : 

		bond0 : `ifconfig bond0 | egrep "inet addr:" |awk '{print $2}'`
		 eth0 :  `ifconfig eth0 | egrep "inet addr:" |awk '{print $2}'`
		 eth1 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`
                 eth2 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`
                 eth3 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`
                 eth4 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`
                 eth5 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`
                 eth6 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`
                 eth7 :  `ifconfig eth1 | egrep "inet addr:" |awk '{print $2}'`

OS release	      : `cat /etc/redhat-release`
Kernel Version        : `uname -r`
Uptime                : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`
Last Reboot Time      : `who -b | awk '{print $3,$4}'`
Current Run Level     : `who -r | awk '{print $2}'`

Last Logins	      : 

`who`
"
`yum list-sec 2>&1`

 if [ $? == 0 ]
 then
	 echo "   -----------------------------"
         echo "  |Satellite  : Looks Configured|"
	 echo "   -----------------------------"
         echo "  Satellite server : "
         grep -i url /etc/sysconfig/rhn/up2date
 else
         echo "   ---------------------------------"
         echo "  |Satellite  : Looks Not Configured|"
	 echo "  |Note:check available sec updates |"
         echo "   ---------------------------------"
	 echo "  |  YUM can not catch any update   |"
         echo "   ---------------------------------"


         yum list-sec 2>&1
 fi


echo -e "

*********************************************************************
			     DNS Status
*********************************************************************
  ---------------------------
 |-> From : /etc/resolve.conf|
  ---------------------------
`grep '^[^#;]' /etc/resolv.conf`

  --------------------
 |-> From : /etc/hosts|
  --------------------
`grep '^[^#;]' /etc/hosts`

*********************************************************************
				NTP
*********************************************************************
  -------------------
 |-> On boot status :|
  -------------------
  `chkconfig ntpd --list`

  -----------------------------
 |-> servers in /etc/ntp.conf :|
  -----------------------------
`grep -i ^server /etc/ntp.conf`
 
  -----------
 |-> Status :|
  -----------

`ntpstat 2>&1`

  ----------------
 |-> NTP Servers :|
  ----------------
`ntpq -p 2>&1`


"
echo -e "

*********************************************************************
                         Multipathing Details
*********************************************************************

"
if [ -f /etc/init.d/PowerPath ]
then
        echo "Server is configures with EMC Multipathing"
        powermt display dev=all 2>&1

elif [ -f /etc/init.d/multipathd ]
then
        echo "Server is configured with native multipath"
	echo "--------------------------------------"
	lsmod | grep -i emc
	echo "--------------------------------------"
        multipath -ll 2>&1

else
        echo "No multipathing"

fi
echo -e "
*********************************************************************
			Fatal Errors in Logs
*********************************************************************
`egrep --color -i "fatal" /var/log/messages 2>&1`

"
echo -e "
*********************************************************************
			Warning Errors in Logs
*********************************************************************
`egrep --color -i "warning" /var/log/messages 2>&1`

"




echo -e "
*********************************************************************
CPU Load - > Threshold < 1 Normal > 1 Caution , > 2 Unhealthy 
*********************************************************************
"
MPSTAT=`which mpstat`
MPSTAT=$?
if [ $MPSTAT != 0 ]
then
	echo "Please install mpstat!"
	#echo "On Debian based systems:"
	#echo "sudo apt-get install sysstat"
	#echo "On RHEL based systems:"
	echo "yum install sysstat"
else
echo -e ""
LSCPU=`which lscpu`
LSCPU=$?
if [ $LSCPU != 0 ]
then
	#RESULT=$RESULT" lscpu required to producre acqurate reults"
	cpus=`cat /proc/cpuinfo |grep -i processor |wc -l`
else
#cpus=`lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}'`
cpus=`cat /proc/cpuinfo |grep -i processor |wc -l`
i=0
while [ $i -lt $cpus ]
do
	echo "CPU$i : `mpstat -P ALL | awk -v var=$i '{ if ($3 == var ) print $4 }' `"
	let i=$i+1
done
fi 
echo -e "
Load Average   : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,`

Heath Status : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}'`
"
fi
echo -e "
*********************************************************************
                         >> SELinux Status <<
*********************************************************************
`sestatus`
"

echo -e "
*********************************************************************
                         >> Firewall Status <<
*********************************************************************
`chkconfig iptables --list 2>&1`
 --------------
|Iptables Rules| 
 --------------
`iptables --line-numbers -n -L 2>&1`

"

echo -e "
*********************************************************************
                         >> Gateway <<
*********************************************************************
`netstat -rn 2>&1`
"

echo -e "
*********************************************************************
                         >> Open Ports <<
*********************************************************************
`sudo nmap -n -PN -sT -sU -p- $HOSTNAME 2>&1`
"
echo -e "
*********************************************************************
                         >> NSM agent <<
*********************************************************************
`awservices list 2>&1`
"


echo -e "
*********************************************************************
                         >> On Boot services <<
*********************************************************************
`chkconfig --list |grep -e 5:on -e 3:on`
"
echo -e "
*********************************************************************
                    >> Running Services /etc/init.d/ <<
*********************************************************************
"
for SERVICE in `ls /etc/init.d/`; do
	service $SERVICE status |sort |grep running 2>&1
done

echo -e "
*********************************************************************
                    >> Stopped Services /etc/init.d/ <<
*********************************************************************
"
for SERVICE in `ls /etc/init.d/`; do
        service $SERVICE status |sort |grep stopped 2>&1
done


echo -e "

*********************************************************************
                             Process
*********************************************************************

=> Top memory using processs/application

PID %MEM RSS COMMAND
`ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10`

=> Top CPU using process/application
`top b -n1 | head -17 | tail -11`

*********************************************************************
Disk Usage - > Threshold < 90 Normal > 90% Caution > 95 Unhealthy
*********************************************************************
"
df -Pkh | grep -v 'Filesystem' > /tmp/df.status
while read DISK
do
	LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
	echo -e $LINE 
	echo 
done < /tmp/df.status
echo -e "

Heath Status"
echo
while read DISK
do
	USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
	if [ $USAGE -ge 95 ] 
	then
		STATUS='Unhealty'
	elif [ $USAGE -ge 90 ]
	then
		STATUS='Caution'
	else
		STATUS='Normal'
	fi
		
        LINE=`echo $DISK | awk '{print $1,"\t",$6}'`
        echo -ne $LINE "\t\t" $STATUS
        echo 
done < /tmp/df.status
rm /tmp/df.status


VOLUME_GROUPS=`vgs 2>&1`
PHYSICAL_VOLUMES=`pvs 2>&1`
LOGICAL_VOLUMES=`lvs 2>&1`
INSTALLED_PACKAGES=`rpm -qa`
AVAILABLE_SECURITY_UPDATES=`yum list-sec 2>&1`
USERS_DETAILS=`cat /etc/passwd |sed 's/:\+/\t/g' | awk '{print $1"\t\t"$6"\t\t\t"$7}'`
VISUDO_DETAILS=`grep "^[^#;]" /etc/sudoers` 
OPEN_SESSION=`netstat -a`
TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`
FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
USEDSWAP=`free -m | tail -1| awk '{print $3}'`
USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
FREESWAP=`free -m |  tail -1| awk '{print $4}'`
FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`

echo -e "

*********************************************************************
                             Volume Groups
*********************************************************************

=> All Volume Groups : 
$VOLUME_GROUPS

*********************************************************************
			     Physical Volumes
*********************************************************************

=> All Physical Volumes :
$PHYSICAL_VOLUMES

*********************************************************************
                             Logical Volume
*********************************************************************

=> All Pysical Volumes :
$LOGICAL_VOLUMES


********************************************************************
			     Memory 
*********************************************************************

=> Physical Memory

Total\tUsed\tFree\t%Free

${TOTALBC}GB\t${USEDBC}GB \t${FREEBC}GB\t$(($FREEMEM * 100 / $TOTALMEM  ))%

=> Swap Memory

Total\tUsed\tFree\t%Free

${TOTALSBC}GB\t${USEDSBC}GB\t${FREESBC}GB\t$(($FREESWAP * 100 / $TOTALSWAP  ))%


********************************************************************
                             Users
*********************************************************************

Login\t\tHome\t\t\tshell

$USERS_DETAILS

********************************************************************
                     Sudo Configuration Details
*********************************************************************

$VISUDO_DETAILS


********************************************************************
                  Installed Packages and Updates
*********************************************************************

=> Available Security Upddates

$AVAILABLE_SECURITY_UPDATES


=> Installed Packages

$INSTALLED_PACKAGES


"
}
FILENAME="health-`hostname`-`date +%y%m%d`-`date +%H%M`.txt"
sysstat > $FILENAME
echo -e "

 =>  Reported file $FILENAME generated in current directory.

"
 $RESULT
