#!/bin/bash
COOKIEJAR="/tmp/tmp.grafana.cookie"
GRAFANA_URL="http://localhost:3000"

 # curl --silent --cookie "$COOKIEJAR" "${GRAFANA_URL}/api/datasources" \
 #   | grep "\"name\":\"${DBNAME}\"" --silent


curl -H 'Content-Type: application/json;charset=UTF-8' --cookie "$COOKIEJAR" "${GRAFANA_URL}/api/datasources"
