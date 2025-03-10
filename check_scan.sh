#!/bin/bash

# check_scan.sh
# works as a nagios plugin to do an nmap scan of a system
# The difference between this script and what I've seen elsewhere
# is check_scan.sh provides a baseline of scan data for comparison.
#
# Copyright (C) 2005 Mark Stingley
# mark AT altsec.info
#
# Updated for IPv6 2025 by jamespo (at) gmail
#
#
# If you need help with your security or systems administration,
# see http://www.altsec.info
#
# Dependencies:  nmap, nagios, linux
#
# README: (1) check the variables below in the section named
#             SET THESE VARIABLES.  Also, verify the path for
#             the GNU/Linux utilities referenced
#         (2) the other requirement is a directory that the
#             nagios user can write to.  I used /etc/nagios,
#             since the directories created there contain
#             baseline nmap scan data
#         (3) the scan files are kept in /etc/nagios/scancheck
#             in the scans directory.  The last scan is simply
#             named by the ip address of the host, such as:
#             192.168.25.3.  The baseline scan for that host
#             would be 192.168.25.3.base
#         (4) to modify the baseline and eliminate warnings
#             about ports, edit the scan file IP-address.base
#             in /etc/nagios/scancheck/scans.  Just be sure
#             that the data is a default "sort", or comparison
#             won't work.  The alternative is to simply cat
#             the last scan file to the baseline, such as:
#             cat #.#.#.# > #.#.#.#.base
#
# Installation: simply copy this script to your plugin directory,
#               make sure it is executable and has the proper
#               ownership
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# See http://www.gnu.org/licenses/licenses.html#GPL or write to the
# Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA  02111-1307  USA
#
# Changelog:
# 20051011 revised from a 2004 script "scancheck.sh"
#
# ToDo:
# 1.  rewrite in perl or C
# 2.  incorporate exclusion lists
# 3.  incorporate critical port lists
#
# - - - - - - - - SET THESE VARIABLES - - - - - - - - - - - - 
BASEDIR="${BASEDIR:-/etc/nagios/scancheck}"  #where to keep everything
                                             #must be nagios user writable
NMAPPATH=/usr/bin                            #where is nmap
#------------------------------------------------------------

#note... to run manually, you have to supply a dummy
#argument 1, since the ip address is arg2

IP=$2

IPFAMILY=$3

IPFILE="${IP}${IPFAMILY}"

if [ ! "$IP" ]; then

   echo "No IP address supplied"
   exit 0

fi


SCANDIR=$BASEDIR/scans
FILEDIR=$BASEDIR/files
CHANGED=0
INITIAL=0


if [ ! -d $BASEDIR ]; then

   mkdir $BASEDIR

fi


if [ ! -d $SCANDIR ]; then

   mkdir $SCANDIR

fi

if [ ! -d $FILEDIR ]; then

   mkdir $FILEDIR

fi


if [ ! -f $SCANDIR/$IPFILE.base ]; then

   touch $SCANDIR/$IPFILE.base
   INITIAL=1

fi

SCANTIME=`/bin/date +%Y%m%d-%H%M`

/usr/bin/nmap $IPFAMILY -sT -P0 $IP | /bin/grep -w open | \
/usr/bin/sort > $SCANDIR/$IPFILE

function get_changes
{
   local flag
   if [ "$1" == opened ]
   then
       flag="-2"
   elif [ "$1" == closed ] 
   then
       flag="-1"
   fi

   /usr/bin/comm $flag -3 $SCANDIR/$IPFILE $SCANDIR/$IPFILE.base \
      | /usr/bin/awk '{print $1}' \
      | /usr/bin/paste -s -d " " -
}

OPENED=`get_changes opened`
CLOSED=`get_changes closed`

if [ $INITIAL -eq 1 ]; then

   /bin/cat $SCANDIR/$IPFILE > $SCANDIR/$IPFILE.base
   echo "Initial scan"
   exit 0
fi

# append_msg LABEL DATA
#   Appends "$LABEL $DATA" to DIFFMSG if DATA is nonempty
#   Also adds ", " between msgs if there are multiple
function append_msg
{
    if [ -n "$2" ]
    then
       if [ -n "$DIFFMSG" ] 
       then
           DIFFMSG="$DIFFMSG, "
       fi
       DIFFMSG="${DIFFMSG}$1 $2"
    fi
}

if [ -n "$OPENED$CLOSED" ]; then
   DIFFMSG=""
   append_msg OPENED "$OPENED"
   append_msg CLOSED "$CLOSED"

   echo "Scan $SCANTIME: $DIFFMSG"
   exit 1
else

   echo "$SCANTIME: no change"
   exit 0

fi


