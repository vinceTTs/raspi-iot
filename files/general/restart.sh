#!/bin/bash

BASE_DIR="/opt/iot"

# Reihenfolge definieren
ORDER=("traefik" "influxdb")

# Zuerst Traefik und InfluxDB
for service in "${ORDER[@]}"; do
    echo ">>> Restarting $service ..."
    cd "$BASE_DIR/$service" || exit 1
    docker compose down -v
    docker compose up -d
done

# Danach alle anderen Ordner
for dir in "$BASE_DIR"/*; do
    name=$(basename "$dir")

    # Überspringe Ordner, die schon oben behandelt wurden
    if [[ " ${ORDER[*]} " == *" $name "* ]]; then
        continue
    fi

    # Nur Ordner mit docker-compose-Datei berücksichtigen
    if [[ -d "$dir" && -f "$dir/docker-compose.yml" ]]; then
        echo ">>> Restarting $name ..."
        cd "$dir" || exit 1
        docker compose down -v
        docker compose up -d
    fi
done

echo ">>> All services restarted."
