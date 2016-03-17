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
import collections
from time import time
from ipaddr import IPv4Address
from maas_common import (get_auth_ref, get_nova_client, status_err, metric,
                         status_ok, metric_bool, print_output)
from novaclient.client import exceptions as exc

SERVER_STATUSES = ['ACTIVE', 'STOPPED', 'ERROR']


def check(args):
    auth_ref = get_auth_ref()
    auth_token = auth_ref['token']['id']
    tenant_id = auth_ref['token']['tenant']['id']

    COMPUTE_ENDPOINT = 'http://{ip}:8774/v2/{tenant_id}' \
                       .format(ip=args.ip, tenant_id=tenant_id)

    try:
        nova = get_nova_client(auth_token=auth_token,
                               bypass_url=COMPUTE_ENDPOINT)
        is_up = True
    except exc.ClientException:
        is_up = False
    # Any other exception presumably isn't an API error
    except Exception as e:
        status_err(str(e))
    else:
        # time something arbitrary
        start = time()
        nova.services.list()
        end = time()
        milliseconds = (end - start) * 1000

        # gather some metrics
        status_count = collections.Counter(
            [s.status for s in nova.servers.list(search_opts={'all_tenants': 1})]
        )

        # Other metrics
        hypervisor_stats = nova.hypervisor_stats.statistics()._info
        hypervisor_count = hypervisor_stats['count']
        hypervisor_workload = hypervisor_stats['current_workload']
        hypervisor_disk_local_gb = hypervisor_stats['local_gb']
        hypervisor_disk_local_gb_used = hypervisor_stats['local_gb_used']
        hypervisor_disk_free_disk_gb = hypervisor_stats['free_disk_gb']
        hypervisor_disk_available_least = hypervisor_stats['disk_available_least']
        hypervisor_memory_total_mb = hypervisor_stats['memory_mb']
        hypervisor_memory_used_mb = hypervisor_stats['memory_mb_used']
        hypervisor_memory_free_mb = hypervisor_stats['free_ram_mb']
        hypervisor_vms_running = hypervisor_stats['running_vms']
        hypervisor_vcpus = hypervisor_stats['vcpus']
        hypervisor_vcpus_used = hypervisor_stats['vcpus_used']

    status_ok()
    metric_bool('nova_api_local_status', is_up)
    # only want to send other metrics if api is up
    if is_up:
        metric('nova_api_local_response_time',
               'double',
               '%.3f' % milliseconds,
               'ms')
        for status in SERVER_STATUSES:
            metric('nova_instances_in_state_%s' % status,
                   'uint32',
                   status_count[status], 'instances')
        metric('nova_hypervisor_count', 'uint32', hypervisor_count, 'hypervisors')
        metric('nova_hypervisor_workload', 'uint32', hypervisor_workload, 'workloads')
        metric('nova_hypervisor_disk_local_gb', 'uint32', hypervisor_disk_local_gb, 'gb')
        metric('nova_hypervisor_disk_local_gb_used', 'uint32', hypervisor_disk_local_gb_used, 'gb')
        metric('nova_hypervisor_free_disk_gb', 'uint32', hypervisor_disk_free_disk_gb, 'gb')
        metric('nova_hypervisor_disk_available_least', 'uint32', hypervisor_disk_available_least, 'gb')
        metric('nova_hypervisor_memory_total_mb', 'uint32', hypervisor_memory_total_mb, 'mb')
        metric('nova_hypervisor_memory_used_mb', 'uint32', hypervisor_memory_used_mb, 'mb')
        metric('nova_hypervisor_memory_free_mb', 'uint32', hypervisor_memory_free_mb, 'mb')
        metric('nova_hypervisor_vms_running', 'uint32', hypervisor_vms_running, 'vms')
        metric('nova_hypervisor_vcpus', 'uint32', hypervisor_vcpus, 'vcpus')
        metric('nova_hypervisor_vcpus_used', 'uint32', hypervisor_vcpus_used, 'vcpus')


def main(args):
    check(args)


if __name__ == "__main__":
    with print_output():
        parser = argparse.ArgumentParser(description='Check nova API')
        parser.add_argument('ip',
                            type=IPv4Address,
                            help='nova API IP address')
        args = parser.parse_args()
        main(args)
