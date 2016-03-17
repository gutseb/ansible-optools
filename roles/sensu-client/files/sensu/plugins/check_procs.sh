#!/bin/bash
#
# Process monitoring script for Sensu
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

#set -e

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

usage ()
{
    echo "Usage: $0 [OPTIONS]"
    echo " -h                   Get help"
    echo " -p <Process Name>    Name of process to check"
    echo " -m <min>             Minimum number of processes expected"
    echo " -M <max>             Minimum number of processes expected"
}

while getopts 'h:p:m:M:' OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;
        p)
            export PROC_NAME=$OPTARG
            ;;
        m)
            export MIN=$OPTARG
            ;;
        M)
            export MAX=$OPTARG
            ;;
        *)
            usage
            exit $STATE_UNKNOWN
            ;;
    esac
done

if [[ ! $PROC_NAME ]] || [[ ! $MIN ]] || [[ ! $MAX ]] ; then
  usage 
  exit $STATE_UNKNOWN
fi

PROCCOUNT=$(ps axwwo user,pid,vsz,rss,pcpu,nlwp,state,etime,time,command | grep $PROC_NAME | grep -v grep | grep -v check_procs.sh | wc -l)

if [[ "$PROCCOUNT" -lt "$MIN" ]] || [[ "$PROCCOUNT" -gt "$MAX" ]] ; then
  echo "$PROC_NAME count ($PROCCOUNT) not within min or max ($MIN - $MAX)"
  exit $STATE_CRITICAL
elif [[ "$PROCCOUNT" -ge "$MIN" ]] || [[ "$PROCCOUNT" -le "$MAX" ]] ; then
  echo "$PROC_NAME count ($PROCCOUNT) is within min or max ($MIN - $MAX)"
  exit $STATE_OK
else
  echo "Unknown Status: $PROC_NAME"
  exit $STATE_UNKNOWN
fi


