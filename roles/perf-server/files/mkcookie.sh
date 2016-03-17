#!/bin/bash 
COOKIEJAR="/tmp/tmp.grafana.cookie"
USER="admin"
PASS="admin"
GRAFANA_URL="http://localhost:3000"

rm -f $COOKIEJAR
curl -H 'Content-Type: application/json;charset=UTF-8' --data-binary "{\"user\":\"${USER}\",\"email\":\"\",\"password\":\"${PASS}\"}" --cookie-jar "$COOKIEJAR" "${GRAFANA_URL}/login"



#curl -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"user":"admin","email":"","password":"admin"}' --cookie-jar '/tmp/tmp.grafana.cookie' http://localhost:3000/login
