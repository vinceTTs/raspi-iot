#!/bin/bash
set -e

USECASE="grafana"
TOKEN_FILE="/var/lib/influxdb2/$USECASE.token"

echo "=== Starting Grafana token creation script ==="
echo "Token file location: $TOKEN_FILE"

# Wait for InfluxDB to be ready
echo "Waiting for InfluxDB API..."
until influx ping &>/dev/null; do
	echo "InfluxDB not ready, waiting..."
	sleep 2
done

echo "InfluxDB API is ready!"

# Check if token already exists
if [ -f "$TOKEN_FILE" ]; then
	echo "Token file already exists at $TOKEN_FILE"
	EXISTING_TOKEN=$(cat "$TOKEN_FILE")
	echo "Existing token (first 20 chars): ${EXISTING_TOKEN:0:20}..."
else
	echo "Creating new token for $USECASE..."
	TOKEN=$(influx auth create --org home --read-buckets --description "$USECASE-read" --json 2>&1 | jq -r '.token' 2>/dev/null || echo "")
	
	if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
		echo "ERROR: Failed to create token. Response was empty or null."
		exit 1
	fi
	
	echo "Generated $USECASE token: ${TOKEN:0:20}..."
	echo "$TOKEN" > "$TOKEN_FILE"
	
	if [ -f "$TOKEN_FILE" ]; then
		echo "SUCCESS: Token file created at $TOKEN_FILE"
		echo "Token file size: $(stat -c%s "$TOKEN_FILE") bytes"
	else
		echo "ERROR: Failed to create token file!"
		exit 1
	fi
fi

echo "=== Grafana token creation script completed ==="

