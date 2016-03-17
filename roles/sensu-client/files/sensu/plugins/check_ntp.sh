#!/bin/bash
#
# NTP/Time monitoring script for Sensu
#
# Copyright © 2016 Red Hat <licensing@redhat.com>
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
    echo " -s <stratum>         Check that stratum meets or exceeds value"
    echo " -w <min>             Warning with offset > x ms"
    echo " -c <max>             Critical with offset > x ms"
}

while getopts 'h:s:w:c:' OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;
        s)
            export STRATUM=$OPTARG
            ;;
        w)
            export WARN=$OPTARG
            ;;
        c)
            export CRIT=$OPTARG
            ;;
        *)
            usage
            exit $STATE_UNKNOWN
            ;;
    esac
done

# Set Defaults
if [[ ! $STRATUM ]] ; then
  STRATUM=15
fi

if [[ ! $WARN ]] ; then
  WARN=10
fi

if [[ ! $CRIT ]] ; then
  CRIT=100
fi

# Check for NTPD or CHRONYD
NTPD=$(systemctl status ntpd)
CHRONYD=$(systemctl status chronyd)

if [[ $(echo $NTPD | grep active | grep -v inactive | wc -l) -gt 0 ]] ; then
  STRATUMCHECK=$(ntpq -c "rv 0 stratum" | awk -F '=' '{print $2}')
  if [[ $STRATUMCHECK -gt $STRATUM ]]; then
    echo "NTP not synced.  Stratum $STRATUMCHECK above limit $STRATUM"
    exit $STATE_CRITICAL
  fi
  OFFSET=$(ntpq -c "rv 0 offset" | awk -F '=' '{print $2}')
  if [[ $(echo "${OFFSET#-} >= ${CRIT}" | sed 's/+//' | bc -l) -eq 1 ]]; then
    echo "NTP offset by $OFFSET >= $CRIT"
    exit $STATE_CRITICAL
  fi
  if [[ $(echo "${OFFSET#-} >= ${WARN}" | sed 's/+//' | bc -l ) -eq 1 ]]; then
    echo "NTP offset by $OFFSET >= $WARN"
    exit $STATE_WARNING
  fi

elif [[ $(echo $CHRONYD | grep active | grep -v inactive | wc -l) -gt 0 ]] ; then
  STRATUMCHECK=$(chronyc tracking | grep Stratum | awk '{print $3}')
  if [[ $STRATUMCHECK -gt $STRATUM ]]; then
    echo "NTP not synced.  Stratum $STRATUMCHECK above limit $STRATUM"
    exit $STATE_CRITICAL
  fi
  
  OFFSET=$(chronyc tracking | grep "Last offset" | awk '{print $4}') 
  if [[ $(echo "${OFFSET#-} >= ${CRIT}" | sed 's/+//' | bc -l) -eq 1 ]]; then
    echo "NTP offset by $OFFSET >= $CRIT"
    exit $STATE_CRITICAL
  fi
  if [[ $(echo "${OFFSET#-} >= ${WARN}" | sed 's/+//' | bc -l ) -eq 1 ]]; then
    echo "NTP offset by $OFFSET >= $WARN"
    exit $STATE_WARNING
  fi
else
  echo "ntpd and chronyd are NOT running.  No time sync service active"
  exit $STATE_CRITICAL
fi


