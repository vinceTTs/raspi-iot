#!/bin/bash
USECASE="telegraf"
TOKEN_FILE="/var/lib/influxdb2/$USECASE.token"

until influx ping &>/dev/null; do
	sleep 2
done


if [ -f "$TOKEN_FILE" ]; then
	exit 0
fi

TOKEN=$(influx auth create --org home --read-buckets --write-buckets --description "$USECASE-read" --json | jq -r '.token')
echo "generated $USECASE token $TOKEN"

echo "$TOKEN" > $TOKEN_FILE
chmod 600 "$TOKEN_FILE"

