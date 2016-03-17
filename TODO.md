# Issues
* setsebool in perf-server and efk-server may not be working... It seemed troublesome and needs retesting...
* iptables rules save appears to run every time.  
* sensu-client reloads every time if on the same host as sensu server (due to the rabbitmq.json being defined by both).  And a check to avoid this
* On all in one monitoring node restart, sensu does not start properly.  It could not connect to redis.  Perhaps and ordering issue?  On boot you must manually start sensu-server and sensu-api
* fluentd client and server cannot both run on the same host
* A unique key should be generated and stored in /etc/graphite-web/local_settings.py.
* mongodb - I am not convinced the metrics per database for collections is right
* mysql - It appears to not collect per DB stats -- only overall.  I think collectd 5.5 (and the updated collectd-mysql) may fix this

# Enhancements
* Convert rcbops sensu metrics checks into a collectd plugin
* redis - Add capability to collect redis stats
* Currently kibana3.conf references local elasticsearch.  This should address the cluster instead
* Add configurable Grafana user/password.  Default is admin/admin
  * Note - Add default grafana dashboards.  Currently its just blank
* Add Grafana SSL.  Check out https://community.rackspace.com/products/f/25/t/6800
* Hostname is getting parsed in my panel of messages by host  (https://github.com/elastic/kibana/issues/648).  I needed to update the default template in order to avoid this...  Basically, I just created a template in /etc/elasticsearch/templates.  Then I have the option to choose 'hostname.raw' as a field that is not analyzed and split up
* Grafana has no data sources defined by default.  Automate this?  
* Grafana has no dashboards defined by default.  Automate this?
* Add graphite SECRET_KEY
* Add graphite auth
* Add kibana auth
* Add ElasticSearch Auth
* Add collection of haproxy, mariadb/galera, mongo, redis, rabbit, or pacemaker logs
* Add user/pass setup for sensu (//github.com/Mayeu/ansible-playbook-sensu/blob/master/templates/uchiwa.json.j2)
- Sensu - add handlers setup (such as email, paging, etc)
* Sensu - Add Rabbit SSL support
* Sensu - Add support to plug into existing Rabbit or Redis infrastructure
* Create/Expand a how-to guide for each component
* Add Manila logs to efk-client role in fluent.conf
* Add Designate logs to efk-client role in fluent.conf
* How to backup/restore each component?  
* Can we grab keystone CADF audit trail and store/report on it?
* Use Ansible Vault to keep passwords safe?
* Implement HA for Central Logging
  * Choose nodes for apache/kibana (haproxy to balance incoming requests from users)
  * Choose nodes for ElasticSearch (haproxy to balance incoming requests from apache or fluentd)
  * Choose nodes for fluentd aggregator (primary/secondary configuration from fluentd clients to aggregation layer)
* Implement HA for Sensu
  * Uchiwa load balanced by haproxy
  * RabbitMQ cluster / mirrored queue for Sensu (haproxy in front to balance connection from sensu - sensu can only point to one IP)
  * Sensu api/server are load balanced by haproxy (client connects via haproxy)
* Implement HA for perf management
* Create a script to automatically generate your inventory based on profiles in OSP Director
