# Cloud-Sync Service

Automatische Synchronisation mehrerer Ordnerpaare mit inotify-basierter Echtzeit-Überwachung.

## Projektstruktur

```
cloud-sync/
├── lib/                    # Scripte
│   └── cloud-sync.sh
├── deamon/                 # Systemd Services
│   ├── cloud-sync.service
│   └── cloud-sync-web.service
├── conf/                   # Konfiguration
│   └── cloud-sync.conf
├── web/                    # Web-Dashboard
│   ├── server.py
│   ├── requirements.txt
│   ├── templates/
│   │   └── dashboard.html
│   └── static/
│       ├── style.css
│       └── app.js
├── install-web.sh          # Automatisches Installations-Script
├── uninstall.sh            # Deinstallations-Script
└── README.md
```

## Installation

### Schnell-Installation mit Script (empfohlen)

Das automatische Installations-Script richtet alles ein:

```bash
# 1. Projekt zum Server kopieren (z.B. via rsync oder scp)
# 2. Auf dem Server ausführen:
cd /pfad/zum/kopierten/projekt/cloud-sync
sudo chmod +x install-web.sh
sudo ./install-web.sh
```

**Das Script führt automatisch aus:**
- ✅ Ermittlung der Server-IP-Adresse
- ✅ Installation aller Abhängigkeiten (Python, Flask, inotify-tools, rsync)
- ✅ Kopieren der Dateien nach `/usr/local/bin/cloud-sync`
- ✅ Einrichtung der Systemd-Services
- ✅ Konfiguration des Web-Servers (Port: 8080, alle Interfaces)
- ✅ Start aller Services

**Nach der Installation:**
- Dashboard erreichbar unter: **http://SERVER-IP:8080** (IP wird automatisch erkannt)
- Sync-Service läuft automatisch
- Server-IP wird in `/usr/local/bin/cloud-sync/web/config.py` gespeichert

**Anpassung des Ports:**
```bash
# Öffne das Script VOR der Installation und ändere die Zeile:
WEB_PORT="8080"              # Gewünschter Port
# Die IP wird automatisch erkannt (bindet auf 0.0.0.0 = alle Interfaces)
```

---

### Manuelle Installation

Falls du die Installation lieber Schritt für Schritt durchführen möchtest:

#### 1. Projekt kopieren

```bash
sudo cp -r cloud-sync /usr/local/bin/
sudo chmod +x /usr/local/bin/cloud-sync/lib/cloud-sync.sh
```

#### 2. Systemd Service einrichten

```bash
sudo cp /usr/local/bin/cloud-sync/deamon/cloud-sync.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cloud-sync.service
```

#### 3. Service starten

```bash
sudo systemctl start cloud-sync.service
```

#### 4. Web-Dashboard (Optional)

Das Web-Dashboard bietet eine Live-Übersicht aller Sync-Jobs:

**Installation:**

```bash
# Python-Abhängigkeiten installieren
sudo apt-get install python3-flask  # Debian/Ubuntu
# oder
sudo pip3 install flask

# Web-Service einrichten
sudo cp /usr/local/bin/cloud-sync/deamon/cloud-sync-web.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cloud-sync-web.service
sudo systemctl start cloud-sync-web.service
```

**Zugriff:**

Dashboard ist erreichbar unter: **http://SERVER-IP:8080**

**Features:**
- ✅ Live-Status aller Sync-Jobs
- ✅ Letzte 10 Synchronisationen pro Job
- ✅ Gesamt-Statistiken (Syncs, Fehler)
- ✅ Live-Log-Anzeige
- ✅ Automatische Aktualisierung alle 2 Sekunden

## Konfiguration

Die Sync-Paare werden in `conf/cloud-sync.conf` definiert:

```ini
# Globale Standardwerte für alle Jobs
[DEFAULTS]
new=true          # Neue Dateien synchronisieren
change=true       # Änderungen synchronisieren
delete=false      # Löschungen synchronisieren

# Job-spezifische Konfiguration
[JobName]
source='/pfad/zum/quellordner'
destination='/pfad/zum/zielordner'
# Optional: Überschreibe DEFAULTS für diesen Job
# new=false
# change=true
# delete=true
```

### Parameter-Beschreibung

| Parameter | Beschreibung | Default |
|-----------|--------------|---------|
| `new` | Neue Dateien werden synchronisiert | `true` |
| `change` | Änderungen an bestehenden Dateien werden synchronisiert | `true` |
| `delete` | Gelöschte Dateien werden auch im Ziel gelöscht | `false` |

### Beispiel-Konfiguration

```ini
[DEFAULTS]
new=true
change=true
delete=false

[Videos]
source='/mnt/hdd/nas/videos'
destination='/mnt/hdd/hetzner/videos'
# Verwendet DEFAULTS

[Backups]
source='/home/user/documents'
destination='/mnt/backup/documents'
delete=true        # Überschreibt DEFAULTS für diesen Job
```

Nach Änderungen an der Konfiguration Service neu starten:

```bash
sudo systemctl restart cloud-sync.service
```

## Verwaltung

### Sync-Service

**Status prüfen:**
```bash
sudo systemctl status cloud-sync.service
```

**Logs anzeigen:**
```bash
sudo tail -f /var/log/cloud-sync.log
# oder
sudo journalctl -u cloud-sync.service -f
```

**Service stoppen:**
```bash
sudo systemctl stop cloud-sync.service
```

**Service neu starten:**
```bash
sudo systemctl restart cloud-sync.service
```

### Web-Dashboard

**Status prüfen:**
```bash
sudo systemctl status cloud-sync-web.service
```

**Logs anzeigen:**
```bash
sudo tail -f /var/log/cloud-sync-web.log
```

**Service neu starten:**
```bash
sudo systemctl restart cloud-sync-web.service
```

**Dashboard öffnen:**
```bash
# Im Browser: http://SERVER-IP:8080
# oder lokal auf dem Server:
curl http://localhost:8080
```

## Anforderungen

### Sync-Service
- `inotify-tools` (für inotifywait)
- `rsync`
- `bash`
- Systemd

### Web-Dashboard (optional)
- `python3` (≥ 3.7)
- `python3-flask`

### Installation der Abhängigkeiten

**Debian/Ubuntu:**
```bash
# Sync-Service
sudo apt-get install inotify-tools rsync

# Web-Dashboard (optional)
sudo apt-get install python3 python3-flask
```

**RHEL/CentOS:**
```bash
# Sync-Service
sudo yum install inotify-tools rsync

# Web-Dashboard (optional)
sudo yum install python3 python3-pip
sudo pip3 install flask
```

## Funktionsweise

- **Initiale Synchronisation beim Start**: 
  - `new=true, change=true`: Alle neuen und geänderten Dateien werden synchronisiert
  - `new=true, change=false`: Nur neue Dateien, keine Updates existierender
  - `new=false, change=true`: Nur Updates existierender Dateien, keine neuen
  - `new=false, change=false`: Keine initiale Sync (nur Echtzeit-Überwachung)
- **Echtzeit-Überwachung**: Änderungen werden sofort erkannt und verarbeitet
  - `new=true`: Neue Dateien werden kopiert (inotify: create, moved_to)
  - `change=true`: Änderungen an Dateien werden kopiert (inotify: modify)
  - `delete=true`: Gelöschte Dateien werden auch im Ziel entfernt (inotify: delete, moved_from)
- **Flexible Konfiguration**: Globale Defaults mit job-spezifischen Überschreibungen
- **Multi-Job**: Mehrere Sync-Paare werden parallel überwacht
- **Logging**: Alle Aktivitäten werden nach `/var/log/cloud-sync.log` protokolliert

## Web-Dashboard

Das Web-Dashboard bietet eine komfortable Oberfläche zur Überwachung aller Sync-Jobs in Echtzeit.

### Dashboard-Features

**Übersichtsseite:**
- 📊 Service-Status und Laufzeit
- 📈 Gesamt-Statistiken (Jobs, Syncs, Fehler)
- 🔄 Automatische Aktualisierung alle 2 Sekunden

**Pro Job:**
- ✅ Status-Indikator (Running/Error)
- 📁 Quell- und Zielpfade
- 📊 Statistiken (Sync-Anzahl, Fehler, letzte Aktivität)
- ⚙️ Aktive Parameter (new/change/delete)
- 📄 Letzte 10 Synchronisationen mit Timestamp

**Live-Log:**
- 📜 Echtzeit-Anzeige der letzten 50 Log-Zeilen
- 🔄 Auto-Scroll und Auto-Refresh

### Technische Details

Der Web-Server:
- Läuft auf Port **8080**
- Parst `/var/log/cloud-sync.log` in Echtzeit
- Keine Änderungen am Bash-Script erforderlich
- Geringer Ressourcenverbrauch (~20-30 MB RAM)
- REST-API für eigene Integrationen

**API-Endpunkte:**
- `GET /api/status` - JSON mit allen Job-Informationen
- `GET /api/logs` - Letzte 100 Log-Zeilen

## Deinstallation

Falls du Cloud-Sync vollständig entfernen möchtest:

```bash
sudo chmod +x /pfad/zum/projekt/uninstall.sh
sudo ./uninstall.sh
```

Das Script entfernt:
- Alle Services (cloud-sync und cloud-sync-web)
- Installierte Dateien in `/usr/local/bin/cloud-sync`
- Systemd Service-Dateien

**Log-Dateien werden NICHT gelöscht** und können manuell entfernt werden:
```bash
sudo rm /var/log/cloud-sync*.log
```

## Troubleshooting

### Service startet nicht

**Problem:** `systemctl status cloud-sync.service` zeigt Fehler

```bash
# Prüfe Details
journalctl -u cloud-sync.service -n 50

# Häufige Ursachen:
# 1. Falsche Zeilenumbrüche (CRLF statt LF)
sed -i 's/\r$//' /usr/local/bin/cloud-sync/lib/cloud-sync.sh

# 2. Fehlende Abhängigkeiten
sudo apt-get install inotify-tools rsync

# 3. Quellordner existiert nicht
# Prüfe Pfade in /usr/local/bin/cloud-sync/conf/cloud-sync.conf
```

### Web-Dashboard nicht erreichbar

**Problem:** http://192.168.20.123 zeigt keine Seite

```bash
# Prüfe ob Service läuft
systemctl status cloud-sync-web.service

# Prüfe Logs
tail -f /var/log/cloud-sync-web.log

# Prüfe ob Port 80 verfügbar ist
sudo netstat -tlnp | grep :80

# Falls Port blockiert, ändere in install-web.sh:
WEB_PORT="8080"  # Alternativer Port

# Firewall prüfen
sudo ufw status
sudo ufw allow 80/tcp  # Oder gewählten Port
```

### Dashboard zeigt keine Daten

**Problem:** Dashboard lädt, aber zeigt keine Jobs

```bash
# Prüfe ob cloud-sync.service läuft
systemctl status cloud-sync.service

# Prüfe Log-Datei
ls -la /var/log/cloud-sync.log
tail -f /var/log/cloud-sync.log

# Prüfe Konfiguration
cat /usr/local/bin/cloud-sync/conf/cloud-sync.conf
```

### Port 80 benötigt root-Rechte

**Problem:** Port 80 kann nicht ohne root geöffnet werden

```bash
# Option 1: Verwende Port > 1024 (z.B. 8080)
# Ändere in install-web.sh: WEB_PORT="8080"

# Option 2: Verwende authbind oder setcap
sudo apt-get install authbind
sudo touch /etc/authbind/byport/80
sudo chmod 500 /etc/authbind/byport/80
sudo chown root:root /etc/authbind/byport/80

# Dann in cloud-sync-web.service ändern:
# ExecStart=authbind --deep /usr/bin/python3 ...
```

## Installationspfad

Das Projekt muss nach `/usr/local/bin/cloud-sync` installiert werden, damit die Service-Datei und relativen Pfade korrekt funktionieren.
