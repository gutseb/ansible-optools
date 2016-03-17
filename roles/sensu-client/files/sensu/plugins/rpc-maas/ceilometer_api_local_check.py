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
from maas_common import (get_auth_ref, get_ceilometer_client, metric_bool,
                         metric, status_ok, status_err, print_output)
from heatclient import exc


def check(args, tenant_id):

    CEILOMETER_ENDPOINT = 'http://{ip}:8777'.format(ip=args.ip)

    try:
        ceilometer = get_ceilometer_client(endpoint=CEILOMETER_ENDPOINT)
        is_up = True
    except exc.HTTPException as e:
        is_up = False
    # Any other exception presumably isn't an API error
    except Exception as e:
        status_err(str(e))
    else:
        # time something arbitrary
        start = time()
        meters = ceilometer.meters.list()
        # Exceptions are only thrown when we iterate over meter
        [i.meter_id for i in meters]
        end = time()
        milliseconds = (end - start) * 1000

    status_ok()
    metric_bool('ceilometer_api_local_status', is_up)
    if is_up:
        # only want to send other metrics if api is up
        metric('ceilometer_api_local_response_time',
               'double',
               '%.3f' % milliseconds,
               'ms')


def main(args):
    auth_ref = get_auth_ref()
    tenant_id = auth_ref['token']['tenant']['id']
    check(args, tenant_id)


if __name__ == "__main__":
    with print_output():
        parser = argparse.ArgumentParser(description='Check Ceilometer API')
        parser.add_argument('ip',
                            type=IPv4Address,
                            help='ceilometer API IP address')
        args = parser.parse_args()
        main(args)
