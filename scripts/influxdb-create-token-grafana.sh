#!/bin/bash
USECASE="grafana"

until influx ping &>/dev/null; do
	sleep 2
done

TOKEN=$(influx auth create --org home --read-buckets --description "$USECASE-read" --json | jq -r '.token')
echo "generated $USECASE token $TOKEN"

echo "$TOKEN" > /var/lib/influxdb2/$USECASE.token

