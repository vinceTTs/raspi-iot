#!/bin/bash
set -e

USECASE="grafana"
# Write directly to the mounted volume
TOKEN_FILE="/var/lib/influxdb2/$USECASE.token"
LOG_FILE="/var/lib/influxdb2/init.log"

{
	echo "=== Starting Grafana token creation script ==="
	echo "Token file location: $TOKEN_FILE"
	echo "Current working directory: $(pwd)"
	echo "InfluxDB data directory contents:"
	ls -la /var/lib/influxdb2/ || echo "Directory not accessible yet"
	
	# Wait for InfluxDB to be ready
	echo "Waiting for InfluxDB API..."
	MAX_RETRIES=30
	RETRY_COUNT=0
	until influx ping &>/dev/null || [ $RETRY_COUNT -ge $MAX_RETRIES ]; do
		echo "InfluxDB not ready, waiting... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
		sleep 2
		RETRY_COUNT=$((RETRY_COUNT + 1))
	done
	
	if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
		echo "ERROR: InfluxDB did not become ready after $MAX_RETRIES attempts"
		exit 1
	fi
	
	echo "InfluxDB API is ready!"
	
	# Create new token
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
		echo "Token file size: $(stat -f%z "$TOKEN_FILE" 2>/dev/null || stat -c%s "$TOKEN_FILE" 2>/dev/null || echo 'unknown') bytes"
	else
		echo "ERROR: Failed to create token file!"
		exit 1
	fi
	
	echo "=== Grafana token creation script completed ==="
} 2>&1 | tee -a "$LOG_FILE"


