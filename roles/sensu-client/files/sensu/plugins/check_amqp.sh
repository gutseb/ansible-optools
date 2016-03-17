#!/bin/bash
#
# OpenStack AMQP Connection monitoring script for Sensu
#
# Copyright © 2014 Red Hat <licensing@redhat.com>
#
# Author: Jon Jozwiak <jjozwiak@redhat.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#set -e

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

usage ()
{
    echo "Usage: $0 [OPTIONS]"
    echo " -h               Get help"
    echo " -p <Process Name>    Name of process to check for AMQP connection"
}

while getopts 'h:p:' OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;
        p)
            export PROC_NAME=$OPTARG
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if ! which netstat >/dev/null 2>&1
then
    echo "netstat (net-tools) is not installed."
    exit $STATE_UNKNOWN
fi

PIDS=$(pidof -x $PROC_NAME)
if [[ -z $PIDS ]]; then 
   echo "Process $PROC_NAME not found"
   exit $STATE_CRITICAL
fi

set -e

CONNECTED="N"
for PID in $PIDS
do
  if KEY=$(sudo /bin/netstat -epta --numeric-hosts 2>/dev/null | grep $PID | grep amqp)
  then
     CONNECTED="Y"
  fi
done

if [[ $CONNECTED == "N" ]] ; then
  echo "$PROC_NAME is not connected to AMQP."
  exit $STATE_CRITICAL
elif [[ $CONNECTED == "Y" ]] ; then
  echo "$PROC_NAME is working."
else
   echo "Unknown Status: $PROC_NAME"
   exit $STATE_UNKNOWN
fi

