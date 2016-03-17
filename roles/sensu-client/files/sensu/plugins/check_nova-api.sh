#!/bin/bash
#
# Nova API monitoring script for Sensu
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

set -e

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

usage ()
{
    echo "Usage: $0 [OPTIONS]"
    echo " -h               Get help"
    echo " -f               Keystone rc file.  Optional."
    echo " -H <Auth URL>    URL for obtaining an auth token"
    echo " -U <username>    Username to use to get an auth token"
    echo " -T <tenant>      Tenant to use to get an auth token"
    echo " -P <password>    Password to use ro get an auth token"
    echo " -E <Endpoint>    URL for Nova endpoint. Optional. If blank, use service catalog"
}

while getopts 'h:f:H:U:T:P:E:' OPTION
do
    case $OPTION in
        h)
            usage
            exit 0
            ;;
        f)
            export KEYSTONERC=$OPTARG
            ;;
        H)
            export OS_AUTH_URL=$OPTARG
            ;;
        U)
            export OS_USERNAME=$OPTARG
            ;;
        T)
            export OS_TENANT_NAME=$OPTARG
            ;;
        P)
            export OS_PASSWORD=$OPTARG
            ;;
        E)
            export NOVA_URL=$OPTARG
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Source keystonerc if it exists
if [[ $KEYSTONERC == "" ]] ; then
   # Set Default
   KEYSTONERC="/etc/sensu/keystonerc_sensu"
fi

if [[ -f $KEYSTONERC ]] ; then
   source $KEYSTONERC
fi


if ! which nova >/dev/null 2>&1
then
    echo "python-novaclient is not installed."
    exit $STATE_UNKNOWN
fi


if ! KEY=$(nova list 2>/dev/null)
then
    echo "Unable to list instances"
    exit $STATE_CRITICAL
fi

count=$(($(nova list 2>/dev/null | wc -l)-4))
responsetime=$((time -p nova list) 2>&1 | grep real | awk '{print $2}')

echo "Nova API is working with $count instances. (response time = $responsetime)"
