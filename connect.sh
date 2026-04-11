#!/bin/bash

set -euo pipefail

MODE="${1:-connect}"

DEFAULT_USER="${SSH_USER:-pi}"
DEFAULT_HOST="${SSH_HOST:-raspberrypi.local}"
DEFAULT_PORT="${SSH_PORT:-22}"

print_usage() {
	cat <<'EOF'
Usage:
  ./connect.sh connect [user] [host] [port] [identity_file]
  ./connect.sh setup-server
  ./connect.sh status

Examples:
  ./connect.sh connect
  ./connect.sh connect pi 192.168.178.50
  ./connect.sh connect pi raspberrypi.local 22 ~/.ssh/id_ed25519
  ./connect.sh setup-server

Defaults:
  user = pi
  host = raspberrypi.local
  port = 22

Environment variables:
  SSH_USER, SSH_HOST, SSH_PORT
EOF
}

print_status() {
	echo "SSH client check..."
	if command -v ssh >/dev/null 2>&1; then
		echo "  OK: ssh client gefunden: $(command -v ssh)"
	else
		echo "  FEHLT: ssh client nicht gefunden"
	fi

	if command -v systemctl >/dev/null 2>&1; then
		echo
		echo "SSH server status..."
		if systemctl is-enabled ssh >/dev/null 2>&1; then
			echo "  OK: ssh service ist aktiviert"
		else
			echo "  HINWEIS: ssh service ist nicht aktiviert"
		fi

		if systemctl is-active ssh >/dev/null 2>&1; then
			echo "  OK: ssh service läuft"
		else
			echo "  HINWEIS: ssh service läuft nicht"
		fi
	fi
}

setup_server() {
	if ! command -v apt-get >/dev/null 2>&1; then
		echo "Dieses Kommando ist für Raspberry Pi OS / Debian gedacht."
		exit 1
	fi

	echo "Aktualisiere Paketlisten..."
	sudo apt-get update

	echo "Installiere OpenSSH-Server und Avahi..."
	sudo apt-get install -y openssh-server avahi-daemon

	echo "Aktiviere SSH-Dienst..."
	sudo systemctl enable --now ssh
	sudo systemctl enable --now avahi-daemon

	echo
	echo "SSH ist eingerichtet."
	echo "Hostname: $(hostname)"

	if command -v hostname >/dev/null 2>&1; then
		echo "mDNS-Adresse: $(hostname).local"
	fi

	if command -v hostname >/dev/null 2>&1; then
		IP_LIST="$(hostname -I 2>/dev/null | xargs || true)"
		if [ -n "$IP_LIST" ]; then
			echo "IP-Adresse(n): $IP_LIST"
		fi
	fi

	echo
	echo "Verbindung von Windows aus zum Beispiel:"
	echo "  ssh ${DEFAULT_USER}@$(hostname).local"
}

connect_to_pi() {
	local user="${2:-$DEFAULT_USER}"
	local host="${3:-$DEFAULT_HOST}"
	local port="${4:-$DEFAULT_PORT}"
	local identity_file="${5:-}"

	if ! command -v ssh >/dev/null 2>&1; then
		echo "Der ssh-Client wurde nicht gefunden."
		echo "Unter Windows nutze entweder den eingebauten OpenSSH-Client oder installiere Git for Windows / PuTTY."
		exit 1
	fi

	echo "Verbinde zu ${user}@${host}:${port} ..."

	if [ -n "$identity_file" ]; then
		exec ssh -i "$identity_file" -p "$port" -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${user}@${host}"
	fi

	exec ssh -p "$port" -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "${user}@${host}"
}

case "$MODE" in
	connect)
		connect_to_pi "$@"
		;;
	setup-server)
		setup_server
		;;
	status)
		print_status
		;;
	-h|--help|help)
		print_usage
		;;
	*)
		echo "Unbekannter Modus: $MODE"
		echo
		print_usage
		exit 1
		;;
esac
