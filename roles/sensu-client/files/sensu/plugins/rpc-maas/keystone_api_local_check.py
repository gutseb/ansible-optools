#!/usr/bin/env python

# Copyright 2014, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
from time import time
from ipaddr import IPv4Address
from maas_common import (get_keystone_client, status_err, status_ok, metric,
                         metric_bool, print_output, get_auth_details)
from keystoneclient.openstack.common.apiclient import exceptions as exc
from keystoneclient.v2_0 import client as k_client

def check(args):

    # Admin Endpoint
    #IDENTITY_ENDPOINT = 'http://{ip}:35357/v2.0/'.format(ip=args.ip)
    # Public Endpoint
    IDENTITY_ENDPOINT = 'http://{ip}:5000/v2.0/'.format(ip=args.ip)

    AUTH_DETAILS = {'OS_USERNAME': None,
                    'OS_PASSWORD': None,
                    'OS_TENANT_NAME': None,
                    'OS_AUTH_URL': None}

    try:
        #keystone = get_keystone_client(endpoint=IDENTITY_ENDPOINT)
        auth_details = get_auth_details()
        keystone = k_client.Client(username=auth_details['OS_USERNAME'],
                                   password=auth_details['OS_PASSWORD'],
                                   tenant_name=auth_details['OS_TENANT_NAME'],
                                   auth_url=IDENTITY_ENDPOINT)
                                   #auth_url=auth_details['OS_AUTH_URL'])
        is_up = True
    except (exc.HttpServerError, exc.ClientException):
        is_up = False
    # Any other exception presumably isn't an API error
    except Exception as e:
        status_err(str(e))
    else:
        # time something arbitrary
        start = time()
        keystone.services.list()
        end = time()
        milliseconds = (end - start) * 1000

        # gather some vaguely interesting metrics to return
        tenant_count = len(keystone.tenants.list())
        user_count = len(keystone.users.list())
        service_count = len(keystone.services.list())
        endpoint_count = len(keystone.endpoints.list())

    status_ok()
    metric_bool('keystone_api_local_status', is_up)
    # only want to send other metrics if api is up
    if is_up:
        metric('keystone_api_local_response_time',
               'double',
               '%.3f' % milliseconds,
               'ms')
        metric('keystone_user_count', 'uint32', user_count, 'users')
        metric('keystone_tenant_count', 'uint32', tenant_count, 'tenants')
        metric('keystone_service_count', 'uint32', service_count, 'services')
        metric('keystone_endpoint_count', 'uint32', endpoint_count, 'endpoints')


def main(args):
    check(args)


if __name__ == "__main__":
    with print_output():
        parser = argparse.ArgumentParser(description='Check keystone API')
        parser.add_argument('ip',
                            type=IPv4Address,
                            help='keystone API IP address')
        args = parser.parse_args()
        main(args)
