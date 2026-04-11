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

  DL_BITS=0
  UL_BITS=0
  LAT=0
  SRV=unknown
  ISP=unknown

  if [ -n "$JSON" ] && echo "$JSON" | jq -e . >/dev/null 2>&1; then
    DL=$(echo "$JSON" | jq -r '.download.bandwidth // empty')
    UL=$(echo "$JSON" | jq -r '.upload.bandwidth // empty')
    LAT_VAL=$(echo "$JSON" | jq -r '.ping.latency // empty')
    SRV_VAL=$(echo "$JSON" | jq -r '.server.name // empty' | tr ' ' '_' | tr -cd '[:alnum:]_')
    ISP_VAL=$(echo "$JSON" | jq -r '.isp // empty' | tr ' ' '_' | tr -cd '[:alnum:]_')

    if [ -n "$DL" ]; then DL_BITS=$(awk "BEGIN {printf \"%.0f\", $DL*8}"); fi
    if [ -n "$UL" ]; then UL_BITS=$(awk "BEGIN {printf \"%.0f\", $UL*8}"); fi
    if [ -n "$LAT_VAL" ]; then LAT="$LAT_VAL"; fi
    if [ -n "$SRV_VAL" ]; then SRV="$SRV_VAL"; fi
    if [ -n "$ISP_VAL" ]; then ISP="$ISP_VAL"; fi
  fi

  LINE="internet_speed,host=raspi,server=$SRV,isp=$ISP download_bps=${DL_BITS}i,upload_bps=${UL_BITS}i,latency_ms=${LAT}"
  curl -s -XPOST "$INFLUX_URL/api/v2/write?org=$INFLUX_ORG&bucket=$INFLUX_BUCKET&precision=s" \
    -H "Authorization: Token $INFLUX_TOKEN" \
    --data-binary "$LINE" >/dev/null || true

  sleep 600
done
