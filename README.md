# Raspberry Pi IoT Setup

Automatisierte Installation von Docker und Docker-Compose auf Raspberry Pi 3 mit Raspberry Pi OS Lite.

## Voraussetzungen

- Raspberry Pi 3 mit Raspberry Pi OS Lite
- Internetverbindung
- SSH-Zugriff oder direkter Zugriff auf den Pi

## Schnellstart

### Lokale Installation (direkt auf dem Raspberry Pi)

1. **Repository auf den Raspberry Pi kopieren:**
   ```bash
   git clone <repository-url> raspi-iot
   cd raspi-iot
   ```

2. **Setup-Script ausführbar machen:**
   ```bash
   chmod +x setup.sh
   ```

3. **Setup starten:**
   ```bash
   ./setup.sh
   ```

4. **Nach der Installation neu einloggen:**
   ```bash
   exit
   # Neu einloggen via SSH oder Console
   ```

5. **Installation testen:**
   ```bash
   docker --version
   docker-compose --version
   ```

### Manuelle Installation

Falls du die Schritte einzeln ausführen möchtest:

1. **Ansible installieren:**
   ```bash
   sudo apt update
   sudo apt install -y ansible
   ```

2. **Inventory-Datei erstellen (`localhost.ini`):**
   ```ini
   [local]
   localhost ansible_connection=local
   ```

3. **Ansible Playbook ausführen:**
   ```bash
   ansible-playbook -i localhost.ini ansible.yml
   ```

4. **Neu einloggen, damit die Docker-Gruppenmitgliedschaft wirksam wird**

## Was wird installiert?

- **docker.io** - Docker Container Runtime (Debian-Paketversion)
- **docker-compose** - Tool für Multi-Container Docker-Anwendungen
- **Benutzer wird zur docker-Gruppe hinzugefügt** - Ermöglicht Docker-Nutzung ohne sudo

## Dateien

- `setup.sh` - Automatisches Setup-Script (empfohlen)
- `ansible.yml` - Ansible Playbook für die Installation
- `localhost.ini` - Lokale Ansible-Inventory (wird vom setup.sh erstellt)

## Troubleshooting

### "Permission denied" beim Ausführen von Docker

Nach der Installation musst du dich neu einloggen oder den Raspberry Pi neu starten:
```bash
sudo reboot
```

### Ansible nicht gefunden

Stelle sicher, dass das Paket installiert ist:
```bash
sudo apt update
sudo apt install -y ansible
```

### Manuelle Installation ohne Ansible

Falls du Ansible nicht verwenden möchtest, kannst du auch manuell installieren:
```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
# Neu einloggen erforderlich
```

## Nächste Schritte

Nach erfolgreicher Installation kannst du:

- Docker-Container starten: `docker run hello-world`
- Docker-Compose Projekte ausführen
- Eigene Container-Anwendungen entwickeln

## Lizenz

MIT
