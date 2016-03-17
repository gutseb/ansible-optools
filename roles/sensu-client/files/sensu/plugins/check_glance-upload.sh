#!/bin/bash
#
# Glance Upload monitoring script for Sensu
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
    echo " -E <Endpoint>    URL for Glance endpoint. Optional. If blank, use service catalog"
    echo " -i <Image>       Location of the image (default: /etc/sensu/cirros-0.3.4-x86_64-disk.img"
    echo " -n <ImageName>   Name of image (default: monitoring-test-image)"
}

# Cirros test image obtained from http://download.cirros-cloud.net

while getopts 'h:f:H:U:T:P:E:i:n:' OPTION
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
            export GLANCE_URL=$OPTARG
            ;;
        i)
            export IMGFILE=$OPTARG
            ;;
        n)
            export IMGNAME=$OPTARG
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

# Set default image name and file if none specified 
if [[ $IMGNAME == "" ]] ; then 
   IMGNAME="monitoring-test-image"
fi
if [[ $IMGFILE == "" ]] ; then 
   IMGFILE="/etc/sensu/cirros-0.3.4-x86_64-disk.img"
fi

if ! which glance >/dev/null 2>&1
then
    echo "python-glanceclient is not installed."
    exit $STATE_UNKNOWN
fi

if [[ ! -f $IMGFILE ]] ; then 
   echo "Test image not found ($IMGFILE)."
   exit $STATE_UNKNOWN
fi

if KEY=$(glance image-show $IMGNAME 2>/dev/null)
then
    echo "Image previously exists.  Cannot test image upload"
    exit $STATE_UNKNOWN
fi


responsetime=$((time -p glance image-create --name $IMGNAME --disk-format raw --container-format bare --file $IMGFILE --is-public false) 2>&1 | grep real | awk '{print $2}')


if ! KEY=$(glance image-show $IMGNAME 2>/dev/null)
then
    echo "Test image not uploaded"
    exit $STATE_CRITICAL
fi

glance image-delete $IMGNAME 2>/dev/null

if KEY=$(glance image-show $IMGNAME 2>/dev/null)
then
    echo "Image delete failed"
    exit $STATE_CRITICAL
fi

echo "Glance Image Upload Successful (response time = $responsetime)"
