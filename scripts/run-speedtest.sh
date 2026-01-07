#!/bin/sh
set -e

# Config
: "${INFLUX_URL:=http://influxdb:8086}"
: "${INFLUX_ORG:=home}"
: "${INFLUX_BUCKET:=network}"
: "${INFLUX_TOKEN:=}"

# Install dependencies (apk) and download Ookla CLI if missing
if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  if command -v apk >/dev/null 2>&1; then
    apk add --no-cache curl jq wget tar
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update && apt-get install -y curl jq wget tar && rm -rf /var/lib/apt/lists/*
  fi
fi

if ! command -v speedtest >/dev/null 2>&1; then
  ARCH=$(uname -m)
  URL=""
  case "$ARCH" in
    armv7l|armhf)
      URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz"
      ;;
    aarch64|arm64)
      URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz"
      ;;
    x86_64|amd64)
      URL="https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz"
      ;;
    *)
      echo "Unsupported architecture: $ARCH" >&2
      exit 1
      ;;
  esac
  TMP=/tmp/speedtest.tgz
  wget -qO "$TMP" "$URL"
  tar -xzf "$TMP" -C /usr/local/bin
  chmod +x /usr/local/bin/speedtest
fi

while true; do
  JSON=$(speedtest -f json --accept-license --accept-gdpr 2>/dev/null || true)
  if [ -n "$JSON" ]; then
    DL=$(echo "$JSON" | jq -r '.download.bandwidth')
    UL=$(echo "$JSON" | jq -r '.upload.bandwidth')
    LAT=$(echo "$JSON" | jq -r '.ping.latency')
    SRV=$(echo "$JSON" | jq -r '.server.name' | tr ' ' '_' | tr -cd '[:alnum:]_')
    ISP=$(echo "$JSON" | jq -r '.isp' | tr ' ' '_' | tr -cd '[:alnum:]_')
    # Convert bytes/s to bits/s if present
    DL_BITS=0
    UL_BITS=0
    if [ "$DL" != "null" ] && [ -n "$DL" ]; then DL_BITS=$(awk "BEGIN {printf \"%.0f\", $DL*8}"); fi
    if [ "$UL" != "null" ] && [ -n "$UL" ]; then UL_BITS=$(awk "BEGIN {printf \"%.0f\", $UL*8}"); fi
    # Line protocol: integer fields with i suffix
    LINE="internet_speed,host=raspi,server=$SRV,isp=$ISP download_bps=${DL_BITS}i,upload_bps=${UL_BITS}i,latency_ms=${LAT}"
    curl -s -XPOST "$INFLUX_URL/api/v2/write?org=$INFLUX_ORG&bucket=$INFLUX_BUCKET&precision=s" \
      -H "Authorization: Token $INFLUX_TOKEN" \
      --data-binary "$LINE" >/dev/null || true
  fi
  sleep 600
done
