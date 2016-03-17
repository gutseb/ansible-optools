#!/bin/bash
COOKIEJAR="/tmp/tmp.grafana.cookie"
GRAFANA_URL="http://localhost:3000"

if [[ $1 == "" ]] ; then
  echo "Usage:  ./upload_dashbard.sh filename.json"
  exit 1 
fi

curl --silent --cookie "$COOKIEJAR" -X POST -H 'Content-Type: application/json' -d @${1} "${GRAFANA_URL}/api/dashboards/db"
