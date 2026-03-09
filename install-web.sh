#!/bin/bash
# Cloud-Sync Web-Dashboard Installations-Script
# Installiert alle Abhängigkeiten und richtet den Web-Server ein

set -e  # Beende bei Fehler

# Konfiguration
INSTALL_DIR="/usr/local/bin/cloud-sync"
WEB_IP="0.0.0.0"
WEB_PORT="8080"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_IP=""  # Wird automatisch ermittelt

# Farben für Ausgabe
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Schritt 1: Root-Check
check_root() {
    log_info "Prüfe Root-Rechte..."
    
    if [ "$EUID" -ne 0 ]; then 
        log_error "Dieses Script muss als root ausgeführt werden!"
        echo "Verwendung: sudo ./install-web.sh"
        return 1
    fi
    
    log_success "Root-Rechte bestätigt"
    return 0
}

# Schritt 1.5: Server-IP automatisch ermitteln
detect_server_ip() {
    log_info "Ermittle Server-IP-Adresse..."
    
    # Versuche verschiedene Methoden zur IP-Ermittlung
    
    # Methode 1: Standard-Interface (eth0, ens33, etc.)
    for interface in eth0 ens33 ens192 enp0s3 enp0s8; do
        local ip=$(ip -4 addr show $interface 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -1)
        if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
            SERVER_IP="$ip"
            log_success "Server-IP erkannt: $SERVER_IP (Interface: $interface)"
            return 0
        fi
    done
    
    # Methode 2: Erstes nicht-localhost Interface
    local ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
    if [ -n "$ip" ]; then
        SERVER_IP="$ip"
        log_success "Server-IP erkannt: $SERVER_IP"
        return 0
    fi
    
    # Methode 3: hostname -I
    local ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
        SERVER_IP="$ip"
        log_success "Server-IP erkannt: $SERVER_IP (via hostname)"
        return 0
    fi
    
    # Fallback: localhost
    SERVER_IP="127.0.0.1"
    log_warning "Konnte externe IP nicht ermitteln, verwende localhost (127.0.0.1)"
    log_warning "Dashboard nur lokal erreichbar!"
    
    return 0
}

# Schritt 2: Konfiguration anzeigen
show_configuration() {
    echo ""
    echo "=================================="
    echo "Cloud-Sync Web-Dashboard Installer"
    echo "=================================="
    echo ""
    log_info "Konfiguration:"
    echo "   Installations-Pfad: $INSTALL_DIR"
    echo "   Server-IP (erkannt): $SERVER_IP"
    echo "   Web-Server bindet auf: $WEB_IP (alle Interfaces)"
    echo "   Web-Server Port: $WEB_PORT"
    echo "   Quell-Verzeichnis: $SCRIPT_DIR"
    echo ""
    echo "   Dashboard erreichbar unter: http://$SERVER_IP:$WEB_PORT"
    echo ""
    return 0
}

# Schritt 3: Abhängigkeiten installieren
install_dependencies() {
    echo "=================================="
    log_info "Schritt 1/6: Installiere Abhängigkeiten..."
    echo ""
    
    # Erkenne Paketmanager
    if command -v apt-get &> /dev/null; then
        log_info "Verwende apt-get (Debian/Ubuntu)..."
        apt-get update -qq || { log_error "apt-get update fehlgeschlagen"; return 1; }
        apt-get install -y python3 python3-pip python3-flask inotify-tools rsync || {
            log_error "Installation der Pakete fehlgeschlagen"
            return 1
        }
        
    elif command -v yum &> /dev/null; then
        log_info "Verwende yum (RHEL/CentOS)..."
        yum install -y python3 python3-pip inotify-tools rsync || {
            log_error "Installation der Pakete fehlgeschlagen"
            return 1
        }
        pip3 install flask || { log_error "Flask-Installation fehlgeschlagen"; return 1; }
        
    elif command -v dnf &> /dev/null; then
        log_info "Verwende dnf (Fedora)..."
        dnf install -y python3 python3-pip python3-flask inotify-tools rsync || {
            log_error "Installation der Pakete fehlgeschlagen"
            return 1
        }
    else
        log_error "Kein unterstützter Paketmanager gefunden!"
        return 1
    fi
    
    # Prüfe ob alle Abhängigkeiten installiert sind
    local missing_deps=0
    
    if ! command -v python3 &> /dev/null; then
        log_error "python3 nicht gefunden"
        missing_deps=1
    fi
    
    if ! command -v inotifywait &> /dev/null; then
        log_error "inotifywait nicht gefunden"
        missing_deps=1
    fi
    
    if ! command -v rsync &> /dev/null; then
        log_error "rsync nicht gefunden"
        missing_deps=1
    fi
    
    if ! python3 -c "import flask" 2>/dev/null; then
        log_error "Flask-Modul nicht gefunden"
        missing_deps=1
    fi
    
    if [ $missing_deps -eq 1 ]; then
        log_error "Nicht alle Abhängigkeiten wurden erfolgreich installiert"
        return 1
    fi
    
    log_success "Alle Abhängigkeiten erfolgreich installiert"
    echo ""
    return 0
}

# Schritt 4: Existierende Services stoppen
stop_services() {
    log_info "Schritt 2/6: Stoppe existierende Services..."
    
    systemctl stop cloud-sync.service 2>/dev/null || true
    systemctl stop cloud-sync-web.service 2>/dev/null || true
    
    # Warte kurz
    sleep 1
    
    # Prüfe ob Services gestoppt sind
    if systemctl is-active --quiet cloud-sync.service; then
        log_warning "cloud-sync.service läuft noch"
    fi
    
    if systemctl is-active --quiet cloud-sync-web.service; then
        log_warning "cloud-sync-web.service läuft noch"
    fi
    
    log_success "Services gestoppt"
    echo ""
    return 0
}

# Schritt 5: Projektdateien kopieren
copy_files() {
    log_info "Schritt 3/6: Kopiere Projektdateien..."
    
    # Erstelle Installations-Verzeichnis
    mkdir -p "$INSTALL_DIR" || {
        log_error "Konnte Verzeichnis $INSTALL_DIR nicht erstellen"
        return 1
    }
    
    # Prüfe ob Quellverzeichnisse existieren
    for dir in lib conf web deamon; do
        if [ ! -d "$SCRIPT_DIR/$dir" ]; then
            log_error "Quellverzeichnis $SCRIPT_DIR/$dir nicht gefunden"
            return 1
        fi
    done
    
    # Kopiere Dateien
    cp -r "$SCRIPT_DIR/lib" "$INSTALL_DIR/" || { log_error "Fehler beim Kopieren von lib/"; return 1; }
    cp -r "$SCRIPT_DIR/conf" "$INSTALL_DIR/" || { log_error "Fehler beim Kopieren von conf/"; return 1; }
    cp -r "$SCRIPT_DIR/web" "$INSTALL_DIR/" || { log_error "Fehler beim Kopieren von web/"; return 1; }
    cp -r "$SCRIPT_DIR/deamon" "$INSTALL_DIR/" || { log_error "Fehler beim Kopieren von deamon/"; return 1; }
    
    # Prüfe ob Dateien existieren
    if [ ! -f "$INSTALL_DIR/lib/cloud-sync.sh" ]; then
        log_error "cloud-sync.sh wurde nicht kopiert"
        return 1
    fi
    
    if [ ! -f "$INSTALL_DIR/web/server.py" ]; then
        log_error "server.py wurde nicht kopiert"
        return 1
    fi
    
    log_success "Dateien erfolgreich kopiert nach $INSTALL_DIR"
    echo ""
    return 0
}

# Schritt 6: Berechtigungen setzen
set_permissions() {
    log_info "Schritt 4/6: Setze Berechtigungen..."
    
    chmod +x "$INSTALL_DIR/lib/cloud-sync.sh" || {
        log_error "Konnte Berechtigungen für cloud-sync.sh nicht setzen"
        return 1
    }
    
    chmod +x "$INSTALL_DIR/web/server.py" || {
        log_error "Konnte Berechtigungen für server.py nicht setzen"
        return 1
    }
    
    # Prüfe ob Dateien ausführbar sind
    if [ ! -x "$INSTALL_DIR/lib/cloud-sync.sh" ]; then
        log_error "cloud-sync.sh ist nicht ausführbar"
        return 1
    fi
    
    if [ ! -x "$INSTALL_DIR/web/server.py" ]; then
        log_error "server.py ist nicht ausführbar"
        return 1
    fi
    
    log_success "Berechtigungen gesetzt"
    echo ""
    return 0
}

# Schritt 7: Web-Server konfigurieren
configure_web_server() {
    log_info "Schritt 5/6: Konfiguriere Web-Server..."
    
    # Erstelle Konfigurations-Datei mit echo (sicherer als heredoc)
    {
        echo "# Web-Dashboard Konfiguration"
        echo "# Automatisch generiert am $(date)"
        echo ""
        echo "# Server-IP (automatisch erkannt)"
        echo "SERVER_IP = \"$SERVER_IP\""
        echo ""
        echo "# Bind-Adresse (0.0.0.0 = alle Interfaces)"
        echo "WEB_HOST = \"$WEB_IP\""
        echo "WEB_PORT = $WEB_PORT"
        echo ""
        echo "# Sync-Service Konfiguration"
        echo "LOG_FILE = \"/var/log/cloud-sync.log\""
        echo "CONFIG_FILE = \"/usr/local/bin/cloud-sync/conf/cloud-sync.conf\""
        echo "MAX_RECENT_SYNCS = 10"
    } > "$INSTALL_DIR/web/config.py"
    
    if [ $? -ne 0 ]; then
        log_error "Konnte config.py nicht erstellen"
        return 1
    fi
    
    # Erstelle angepasste Service-Datei für Web-Dashboard mit echo
    {
        echo "[Unit]"
        echo "Description=Cloud-Sync Web Dashboard"
        echo "After=network.target cloud-sync.service"
        echo ""
        echo "[Service]"
        echo "Type=simple"
        echo "ExecStart=/usr/bin/python3 $INSTALL_DIR/web/server.py"
        echo "Restart=always"
        echo "User=root"
        echo "WorkingDirectory=$INSTALL_DIR/web"
        echo "Environment=\"WEB_HOST=$WEB_IP\""
        echo "Environment=\"WEB_PORT=$WEB_PORT\""
        echo "StandardOutput=append:/var/log/cloud-sync-web.log"
        echo "StandardError=append:/var/log/cloud-sync-web.log"
        echo ""
        echo "[Install]"
        echo "WantedBy=multi-user.target"
    } > "$INSTALL_DIR/deamon/cloud-sync-web.service"
    
    if [ $? -ne 0 ]; then
        log_error "Konnte cloud-sync-web.service nicht erstellen"
        return 1
    fi
    
    # Prüfe ob Dateien erstellt wurden
    if [ ! -f "$INSTALL_DIR/web/config.py" ]; then
        log_error "config.py wurde nicht erstellt"
        return 1
    fi
    
    if [ ! -f "$INSTALL_DIR/deamon/cloud-sync-web.service" ]; then
        log_error "cloud-sync-web.service wurde nicht erstellt"
        return 1
    fi
    
    log_success "Web-Server konfiguriert für $WEB_IP:$WEB_PORT"
    echo ""
    return 0
}

# Schritt 8: Systemd Services einrichten
setup_systemd_services() {
    log_info "Schritt 6/6: Richte Systemd Services ein..."
    
    # Kopiere Service-Dateien
    cp "$INSTALL_DIR/deamon/cloud-sync.service" /etc/systemd/system/ || {
        log_error "Konnte cloud-sync.service nicht kopieren"
        return 1
    }
    
    cp "$INSTALL_DIR/deamon/cloud-sync-web.service" /etc/systemd/system/ || {
        log_error "Konnte cloud-sync-web.service nicht kopieren"
        return 1
    }
    
    # Prüfe ob Service-Dateien existieren
    if [ ! -f /etc/systemd/system/cloud-sync.service ]; then
        log_error "cloud-sync.service nicht in /etc/systemd/system/ gefunden"
        return 1
    fi
    
    if [ ! -f /etc/systemd/system/cloud-sync-web.service ]; then
        log_error "cloud-sync-web.service nicht in /etc/systemd/system/ gefunden"
        return 1
    fi
    
    # Systemd neu laden
    systemctl daemon-reload || {
        log_error "systemctl daemon-reload fehlgeschlagen"
        return 1
    }
    
    # Services aktivieren
    systemctl enable cloud-sync.service || {
        log_error "Konnte cloud-sync.service nicht aktivieren"
        return 1
    }
    
    systemctl enable cloud-sync-web.service || {
        log_error "Konnte cloud-sync-web.service nicht aktivieren"
        return 1
    }
    
    log_success "Systemd Services eingerichtet und aktiviert"
    echo ""
    return 0
}

# Schritt 9: Services starten und prüfen
start_and_verify_services() {
    log_info "Starte Services..."
    echo ""
    
    # Starte cloud-sync Service
    log_info "Starte cloud-sync.service..."
    systemctl start cloud-sync.service || {
        log_error "Konnte cloud-sync.service nicht starten"
        journalctl -u cloud-sync.service -n 20 --no-pager
        return 1
    }
    
    sleep 2
    
    if systemctl is-active --quiet cloud-sync.service; then
        log_success "cloud-sync.service läuft"
    else
        log_error "cloud-sync.service ist nicht aktiv"
        systemctl status cloud-sync.service --no-pager -l
        return 1
    fi
    
    # Starte cloud-sync-web Service
    log_info "Starte cloud-sync-web.service..."
    systemctl start cloud-sync-web.service || {
        log_error "Konnte cloud-sync-web.service nicht starten"
        journalctl -u cloud-sync-web.service -n 20 --no-pager
        return 1
    }
    
    sleep 3
    
    if systemctl is-active --quiet cloud-sync-web.service; then
        log_success "cloud-sync-web.service läuft"
    else
        log_error "cloud-sync-web.service ist nicht aktiv"
        echo ""
        log_info "Letzte Log-Einträge:"
        tail -20 /var/log/cloud-sync-web.log
        echo ""
        systemctl status cloud-sync-web.service --no-pager -l
        return 1
    fi
    
    echo ""
    log_success "Alle Services erfolgreich gestartet"
    echo ""
    return 0
}

# Schritt 10: Abschluss-Informationen
show_completion_info() {
    echo "=================================="
    echo -e "${GREEN}✨ Installation erfolgreich!${NC}"
    echo "=================================="
    echo ""
    echo "📍 Web-Dashboard erreichbar unter:"
    echo "   http://$SERVER_IP:$WEB_PORT"
    if [ "$SERVER_IP" != "127.0.0.1" ]; then
        echo "   http://127.0.0.1:$WEB_PORT (lokal auf dem Server)"
    fi
    echo ""
    echo "💡 Der Server lauscht auf allen Interfaces (0.0.0.0:$WEB_PORT)"
    echo "   IP-Adresse wurde automatisch erkannt: $SERVER_IP"
    echo ""
    echo "📝 Nützliche Befehle:"
    echo "   Status Sync:       systemctl status cloud-sync.service"
    echo "   Status Web:        systemctl status cloud-sync-web.service"
    echo "   Logs Sync:         tail -f /var/log/cloud-sync.log"
    echo "   Logs Web:          tail -f /var/log/cloud-sync-web.log"
    echo "   Sync neu laden:    systemctl restart cloud-sync.service"
    echo "   Web neu laden:     systemctl restart cloud-sync-web.service"
    echo ""
    echo "📁 Konfiguration:"
    echo "   Sync-Jobs:         $INSTALL_DIR/conf/cloud-sync.conf"
    echo "   Web-Server:        $INSTALL_DIR/web/config.py"
    echo ""
    echo "⚠️  Hinweis: Nach Änderungen an cloud-sync.conf Service neu starten!"
    echo ""
    return 0
}

# Main-Funktion
main() {
    # Schritt 1: Root-Check
    if ! check_root; then
        exit 1
    fi
    
    # Schritt 1.5: Server-IP ermitteln
    if ! detect_server_ip; then
        log_warning "Konnte Server-IP nicht ermitteln, fahre trotzdem fort"
    fi
    
    # Schritt 2: Konfiguration anzeigen
    show_configuration
    
    # Schritt 3: Abhängigkeiten installieren
    if ! install_dependencies; then
        log_error "Installation der Abhängigkeiten fehlgeschlagen"
        echo "Bitte behebe die Fehler und versuche es erneut."
        exit 1
    fi
    
    # Schritt 4: Services stoppen
    if ! stop_services; then
        log_error "Fehler beim Stoppen der Services"
        exit 1
    fi
    
    # Schritt 5: Dateien kopieren
    if ! copy_files; then
        log_error "Fehler beim Kopieren der Dateien"
        exit 1
    fi
    
    # Schritt 6: Berechtigungen setzen
    if ! set_permissions; then
        log_error "Fehler beim Setzen der Berechtigungen"
        exit 1
    fi
    
    # Schritt 7: Web-Server konfigurieren
    if ! configure_web_server; then
        log_error "Fehler bei der Web-Server Konfiguration"
        exit 1
    fi
    
    # Schritt 8: Systemd Services einrichten
    if ! setup_systemd_services; then
        log_error "Fehler bei der Systemd-Konfiguration"
        exit 1
    fi
    
    # Schritt 9: Services starten und verifizieren
    if ! start_and_verify_services; then
        log_error "Fehler beim Starten der Services"
        echo ""
        log_info "Troubleshooting-Tipps:"
        echo "1. Prüfe die Logs: tail -f /var/log/cloud-sync-web.log"
        echo "2. Prüfe Service-Status: systemctl status cloud-sync-web.service"
        echo "3. Teste manuell: python3 $INSTALL_DIR/web/server.py"
        exit 1
    fi
    
    # Schritt 10: Erfolgsmeldung
    show_completion_info
    
    exit 0
}

# Script starten
main
