#!/bin/bash -e
################################################################################
# This script sets up the default data source for Grafana
################################################################################

#GRAFANA_URL="http://192.168.220.250:3000"
GRAFANA_URL="http://ansibleoptools.jonjozwiak.com:3000"
USER="admin"
PASS="admin"
DBNAME="graphite"
DBTYPE="graphite"
DBACCESS="proxy"
DBURL="http://localhost/"

COOKIEJAR=$(mktemp)
### Comment out the trap to keep the cookie for troubleshooting if needed
trap 'unlink ${COOKIEJAR}' EXIT

curl -H 'Content-Type: application/json;charset=UTF-8' --data-binary "{\"user\":\"${USER}\",\"email\":\"\",\"password\":\"${PASS}\"}" --cookie-jar "$COOKIEJAR" "${GRAFANA_URL}/login"

function setup_grafana_session {
  if ! curl -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary "{\"user\":\"${USER}\",\"email\":\"\",\"password\":\"${PASS}\"}" \
    --cookie-jar "$COOKIEJAR" \
    "${GRAFANA_URL}/login" > /dev/null 2>&1 ; then
    echo "Grafana Session: Couldn't store cookies at ${COOKIEJAR}"
    exit 1
  fi
}

function grafana_has_data_source {
  setup_grafana_session
  curl --silent --cookie "$COOKIEJAR" "${GRAFANA_URL}/api/datasources" \
    | grep "\"name\":\"${DBNAME}\"" --silent
}

function grafana_create_data_source {
  setup_grafana_session
  curl --cookie "$COOKIEJAR" \
       -X PUT \
       --silent \
       -H 'Content-Type: application/json;charset=UTF-8' \
       --data-binary "{\"name\":\"${DBNAME}\",\"type\":\"${DBTYPE}\",\"url\":\"${DBURL}\",\"access\":\"${DBACCESS}\",\"database\":\"\",\"user\":\"\",\"password\":\"\",\"basicAuth\":false,\"basicAuthUser\":\"\",\"basicAuthPassword\":\"\",\"isDefault\":true}" \
       "${GRAFANA_URL}/api/datasources" 2>&1 | grep 'Datasource added' --silent;
}

## Orig --data-binary for create data source:
#        --data-binary "{\"name\":\"${DBNAME}\",\"type\":\"${DBTYPE}\",\"url\":\"${DBURL}\",\"access\":\"${DBACCESS}\",\"database\":\"${DBNAME}\",\"user\":\"\",\"password\":\"\"}" \


### [{"id":2,"orgId":1,"name":"graphite","type":"graphite","access":"proxy","url":"http://localhost/","password":"","user":"","database":"","basicAuth":false,"basicAuthUser":"","basicAuthPassword":"","isDefault":true,"jsonData":null}]

function setup_grafana {
  if grafana_has_data_source "${DBNAME}"; then
    echo "Grafana: Data source ${DBNAME} already exists"
    exit 0
  else
    if grafana_create_data_source "${DBNAME}"; then
      echo "Grafana: Data source ${DBNAME} created"
      exit 0
    else
      echo "Grafana: Data source ${DBNAME} could not be created"
      exit 1
    fi
  fi
}


setup_grafana
