# Plugins for Sensu
These are basic plugins used to monitor systems 

## General System Checks

## OpenStack Basic Checks - Test every minutes
Test | Command | Script
---- | ------- | ------ 
Flavor list   | nova flavor-list | 
Instance list | nova list        | check_nova-api.sh
Image List    | glance image-list | check_glance-api.sh
Meter List    | ceilometer meter-list | check_ceilometer-api.sh
Volume List   | cinder list | check_cinder-api.sh
Stack List    | heat stack-list | check_heat-api.sh
Network List  | neutron net-list | check_neutron-api.sh
Token Get     | keystone token-get or openstack token issue | check_keystone-api.sh
Big Data Cluster List | sahara cloud-list | check_sahara-api.sh
Database Instance List | trove list | check_trove-api.sh

## OpenStack Functional Checks - Test every 5 minutes
Functionality | Script
------------- | ------
Create / Delete Flavor | 
Create / Delete Keypair | 
Create / Delete Security Group | 
Create / Delete Volume | check_cinder-create.sh
Create / Delete Snapshot | 
Create / Delete Image | check_glance-upload.sh
Create / Delete Floating IP |
Create / Delete Stack | 
Create / Delete User |
Log into Dashboard | 
Create Volume and attach to instance |
Create Floating IP & validate instance connectivity |
Boot instance / Delete instance |
Boot from Snapshot / Delete |
TODO - Ceilometer test | 

## Component Checks
---> Add amqp connectivity here
---> Process checks 
---> Pacemaker checks
---> HAproxy checks
---> Galera Sync checks
---> MongoDB checks
---> Rabbit checks 
---> Redis checks


# Sensu Community Plugins 
check-cpu.sh - https://github.com/sensu-plugins/sensu-plugins-cpu-checks.git
check-memory.sh - https://github.com/sensu-plugins/sensu-plugins-memory-checks.git
check-memory-percent.sh - https://github.com/sensu-plugins/sensu-plugins-memory-checks.git
check-swap.sh - https://github.com/sensu-plugins/sensu-plugins-memory-checks.git
check-swap-percent.sh - https://github.com/sensu-plugins/sensu-plugins-memory-checks.git


# Validate you can connect to mysql
mysql-alive.rb -h db01 --ini '/etc/sensu/my.cnf
