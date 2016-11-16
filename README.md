# Ansible RHEL OSP Operational Tools

These playbooks can be used to deploy the RHEL OSP Ops Tools in an all-in-one or distributed architecture.  Currently only all-in-one is tested.  Tools are broken down into the follwing categories:

*Availability Monitoring:* Sensu with the Uchiwa Dashboard

*Central Log Monitoring:* Kibana Dashboard, ElasticSearch for storage, and Fluentd for log collection

*Performance Monitoring:* Grafana Dashboard, Graphite/Carbon for storage, and Collectd for metrics collection

NOTE: Your ops tools server must be able to talk to your OSP environment on some network

## Installation
Follow these steps to install the Ops Tools.  Note, this assumes you have a RHEL 7 node installed for the operational tools to reside on as well as an OpenStack deployment to connect them to.  
1. Clone this repo and install ansible
```
git clone https://github.com/jonjozwiak/ansible-optools.git
yum -y localinstall https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
```
2. Update the inventory/hosts to properly reflect your environment
There is an example (what I tested with) in this repo.  Details as follows:

  - ansibleoptools -> RHEL 7 host for all-in-one opstools node
  - 192.168.220.61 RHEL OSP 7 Ceph node (provisioned via OSP-d)
  - 192.168.220.62 RHEL OSP 7 Compute node (provisioned via OSP-d)
  - 192.168.220.63 RHEL OSP 7 Controller node (provisioned via OSP-d)

3. Review group_vars/all to see if it fits your environment.  Note if you have local repos you will likely need to update roles/common/files/\*.repo to accurately reflect your environment

4. For OpenStack API monitoring you will need a user with the ADMIN role.  Update these variables in group_vars/all (Setting the user/password to align with your environment:
```
  os_username: monitoring
  os_password: sensu
  os_tenant_name: monitoring
  os_auth_url: http://keystone_host:5000/v2.0/
  # os_auth_url: http://keystone_host:5000/v3/
  # os_domain_name: default

  # If you need to create a tenant/user for this, here's the steps:
  . keystonerc_admin      # or overcloudrc
  keystone tenant-create --name monitoring --description "Monitoring Tenant"
  keystone user-create --name monitoring --tenant monitoring --pass "sensu" --email sensumonitorexample.com
  keystone user-role-add --user monitoring --tenant monitoring --role admin

  # Also get the cirros image for glance image upload testing
  curl -k -o /etc/sensu/cirros-0.3.4-x86_64-disk.img \
   https://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
  chown sensu:sensu /etc/sensu/cirros-0.3.4-x86_64-disk.img
```
5. Run the playbook

```
# Run against all hosts
ansible-playbook -i inventory/hosts optools.yml

# Run the playbook against only clients:
ansible-playbook -i inventory/hosts optools.yml --limit clients

# Run against a specific role:
ansible-playbook -i inventory/hosts optools.yml --tags efk-client
```

## Using the tools
The deployment will setup the following URLs for access:
- Uchiwa: *sensu-server-ip*:3001 (default is 3000, but changed due to collision)
- Graphite: *perf-server-ip*:80
- Grafana: *perf-server-ip*:3000 (default user/pass is admin/admin)
- ElasticSearch: *log-server-ip*:9200
- Kibana: *log-server-ip*:8080/kibana  (Kibana on port 8080 ONLY if on same host as graphite.  Otherwise it just on port 80 aliased to /kibana)

### ElasticSearch Notes
```
# ElasticSearch - List Stats (in clean format)
curl http://<efk-server>:9200/_stats | python -mjson.tool | more
# ElasticSearch Cluster Status
curl http://<efk-server>:9200/_cluster/health?pretty=true
# ElasticSearch Settings
curl "localhost:9200/_nodes?pretty=true&settings=true"

# ElasticSearch clean up all the data
curl -XDELETE 'http://localhost:9200/*/'
```

NOTE: If your log level is verbose=False, you will not capture any INFO messages.  Director defaults to false.  Packstack defaults to true

### Kibana Notes

#### Where are kibana dashboards saved?
They are written in json to ElasticSearch in kibana-int index type of dashboard.  In kibana 3.1.2, a dashboard can also be saved in /usr/share/kibana/app/dashboards and they will be available.  

In kibana 4 this will change and it is stored in a .kibana index.  See these:
- https://github.com/elastic/kibana/issues/2741
- https://github.com/elastic/kibana/issues/1552
- https://github.com/elastic/kibana/pull/3573

### Graphite Notes
Graphite cannot use Django 1.8.4 from the OpenStack repo.  It ships with an earlier Django.  This error shows during the graphite syncdb...

Link to the issue as follows: https://github.com/graphite-project/graphite-web/issues/1219

Graphite data is stored in /var/lib/graphite/whisper on the perf server.  You can delete collections directly to clean up data.  If you want to check what is in data files, the following is really useful:
```
git clone https://github.com/graphite-project/whisper.git
cd whisper/bin
./whisper-dump.py /var/lib/graphite/whisper/collectd/<server name>/.../filename.wsp
```

### Fluentd Notes
If a log file does not exist on the host, fluentd will say </pair> is not used in /var/log/messages.  If it does not have permissions, it will give an error frequently indicating permission denied on a specific log

NOTE: This also means you cannot run the server components on the RHEL OSP Controllers as there will be a conflict (unless you isolate them in a Docker container).  

### Grafana Notes
#### How to connect Grafana to the Graphite data Sources?

By default, running the ansible playbook should automatically connect to the graphite data source.  However, if you need to do this in the UI, access the Grafana URL, Click Data Sources, and Add New

Name: graphite             <br>
Default: yes (tick)        <br>
Type: Graphite             <br>

Url: http://localhost/     <br>
Access: proxy              <br>
Basic Auth: no (unticked)  <br>

#### Overview of how to build Grafana dashboard
https://www.youtube.com/watch?v=sKNZMtoSHN4&index=7&list=PLDGkOdUX1Ujo3wHw9-z5Vo12YLqXRjzg2

#### API Reference
If you happen to need to upload dashboards through the API, here's a reference:

http://docs.grafana.org/reference/http_api/

I also created some scripts in /etc/grafana to create a cookie and then upload or delete dashboards

### HAProxy Notes
In order to monitor HAProxy stats, you need the stats socket enabled.  RHEL OSP has the stats uri enabled by default, but not the socket.  These ansible runbooks will enable the socket (as I've not found a way to get 'show info' from the http site.  An example of the configuration in /etc/haproxy/haproxy.cfg is as follows:
```
### Stats Socket
global
  stats socket /var/run/haproxy.sock mode 600 level admin
  stats timeout 2m #Wait up to 2 minutes for input
# Access stats via command line:
# echo "show info;show stat" | nc -U /var/run/haproxy.sock

### Stats URI  - Replace xxx.xxx.xxx.xxx with your IP to listen on
listen haproxy.stats
  bind xxx.xxx.xxx.xxx:1993
  mode http
  stats enable
  stats uri /
# Access stats via command line:
# curl "http://xxx.xxx.xxx.xxx:1993/?stats;csv"
### Or if you need user auth:
# curl -u <MyUser>:<MyPASSWORD> "http://xxx.xxx.xxx.xxx:1993/haproxy?stats;csv" 2>/dev/null | grep "^$1,$2" | cut -d, -f $3
```

### MongoDB Notes
Stats are gathered by authenticating with the client and parsing results of commands:
```
grep ^bind /etc/mongod.conf
mongo <bind ip>
use ceilometer
db.serverStatus()
db.stats()
```

### Redis Notes
To look at Redis stats
```
egrep "^bind|^port" /etc/redis.conf
redis-cli -h <ip> -p 6379 -c info
```

## References
For monitoring implementation I created several checks myself, but also used a number of other peoples work as follows:

* Rackspace monitoring as a service              <br>
https://github.com/rcbops/maas                   <br>
These cover the majority of OpenStack monitoring needs.  I tweaked them to first work as sensu metrics checks:
http://develify.com/sensu-metrics-to-graphite-with-tcp-handler/
But plan to update these to work as a collectd plugin

* Ceph monitoring                                <br>
A great plugin and dashboard were available here: https://github.com/rochaporto/collectd-ceph.  There were a couple tweaks I made to get this working, altough they were already issues or pull requests related to them. A fork with active commits,here https://github.com/grinapo/collectd-ceph

* OpenStack monitoring                           <br>
 Also good detail here, although I did not directly use it:
 http://github.com/rochaporto/collectd-openstack

* Performance Dashboards and metrics             <br>
The Red Hat Guidelines and Considerations when Scaling your RHEL OSP cloud calls out a good resource called Browbeat.  I've taken some dashboards and inspiration from it.  Browbeat can be found here:
https://github.com/jtaleric/browbeat

* HAProxy Monitoring                             <br>
I used https://github.com/wglass/collectd-haproxy which worked mostly out of the box to collect metrics

* MongoDB Monitoring                             <br>
Keeping in my theme of python plugins for collectd, I pulled https://github.com/sebest/collectd-mongodb
