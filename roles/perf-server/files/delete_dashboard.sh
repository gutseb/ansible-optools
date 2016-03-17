#!/bin/bash
COOKIEJAR="/tmp/tmp.grafana.cookie"
GRAFANA_URL="http://localhost:3000"

if [[ $1 == "" ]] ; then
  echo "Usage:  ./delete_dashbard.sh dashboard-name"
  exit 1 
fi

curl --silent --cookie "$COOKIEJAR" -X DELETE -H 'Content-Type: application/json' "${GRAFANA_URL}/api/dashboards/db/${1}"
