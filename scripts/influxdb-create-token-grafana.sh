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
	
	# Create new token with authentication
	echo "Creating new token for $USECASE..."
	
	# Export credentials for influx CLI
	export INFLUXDB_HOST="http://localhost:8086"
	export INFLUXDB_USERNAME="admin"
	export INFLUXDB_PASSWORD="admin123"
	export INFLUXDB_ORG="home"
	
	TOKEN=$(influx auth create \
		--org home \
		--username admin \
		--password admin123 \
		--read-buckets \
		--description "$USECASE-read" \
		--json 2>&1 | jq -r '.token' 2>/dev/null || echo "")
	
	echo "Token creation output: $TOKEN"
	
	if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
		echo "ERROR: Failed to create token. Response was: $TOKEN"
		echo "Trying alternative auth method..."
		# Try with host flag
		TOKEN=$(influx auth create \
			--host http://localhost:8086 \
			--org home \
			--username admin \
			--password admin123 \
			--read-buckets \
			--description "$USECASE-read" \
			--json 2>&1 | jq -r '.token' 2>/dev/null || echo "")
		echo "Alternative method result: $TOKEN"
	fi
	
	if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
		echo "ERROR: Still failed to create token"
		exit 1
	fi
	
	echo "Generated $USECASE token: ${TOKEN:0:20}..."
	echo "$TOKEN" > "$TOKEN_FILE"
	
	if [ -f "$TOKEN_FILE" ]; then
		echo "SUCCESS: Token file created at $TOKEN_FILE"
		FILE_SIZE=$(stat -c%s "$TOKEN_FILE" 2>/dev/null || stat -f%z "$TOKEN_FILE" 2>/dev/null || echo 'unknown')
		echo "Token file size: $FILE_SIZE bytes"
		echo "Token content (first 30 chars): $(head -c 30 "$TOKEN_FILE")"
	else
		echo "ERROR: Failed to create token file!"
		exit 1
	fi
	
	echo "=== Grafana token creation script completed ==="
} 2>&1 | tee -a "$LOG_FILE"


