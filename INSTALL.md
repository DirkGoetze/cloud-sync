# Cloud-Sync - Schnell-Installation

## Automatische Installation (empfohlen)

### 1. Projekt zum Server kopieren

```bash
# Auf Windows (in PowerShell/CMD):
scp -r L:\clouds\onedrive\Dirk\projects\cloud-sync user@192.168.20.123:/tmp/

# Oder via rsync:
rsync -avz L:\clouds\onedrive\Dirk\projects\cloud-sync user@192.168.20.123:/tmp/
```

### 2. Auf dem Server installieren

```bash
# Als root/sudo
cd /tmp/cloud-sync
chmod +x install-web.sh
sudo ./install-web.sh
```

### 3. Dashboard öffnen

Die Server-IP wird automatisch erkannt und am Ende der Installation angezeigt.

Im Browser: **http://SERVER-IP:8080**

(Die IP-Adresse wird während der Installation automatisch ermittelt und angezeigt)

---

## Konfiguration anpassen

### Port ändern

**VOR der Installation** `install-web.sh` bearbeiten:

```bash
nano install-web.sh

# Zeile 13 ändern:
WEB_PORT="8080"              # Gewünschter Port (empfohlen: >1024)

# Die Server-IP wird automatisch erkannt und muss nicht angepasst werden
# Der Server bindet auf 0.0.0.0 (alle Interfaces) und ist damit überall erreichbar
```

### Nach der Installation

Die erkannte IP-Adresse wird gespeichert in:
```bash
/usr/local/bin/cloud-sync/web/config.py
```

Du kannst diese Datei bei Bedarf manuell anpassen.

### Sync-Jobs konfigurieren

**NACH der Installation** Config bearbeiten:

```bash
sudo nano /usr/local/bin/cloud-sync/conf/cloud-sync.conf

# Jobs hinzufügen/ändern:
[MeinJob]
source='/pfad/zur/quelle'
destination='/pfad/zum/ziel'
new=true
change=true
delete=false

# Service neu starten:
sudo systemctl restart cloud-sync.service
```

---

## Prüfen ob alles läuft

```bash
# Services prüfen
sudo systemctl status cloud-sync.service
sudo systemctl status cloud-sync-web.service

# Logs ansehen
tail -f /usr/local/bin/cloud-sync/log/cloud-sync.log
tail -f /usr/local/bin/cloud-sync/log/cloud-sync-web.log
```

---

## Deinstallation

```bash
cd /tmp/cloud-sync
chmod +x uninstall.sh
sudo ./uninstall.sh
```

---

## Hilfe bei Problemen

Siehe [README.md](README.md) Abschnitt "Troubleshooting"
