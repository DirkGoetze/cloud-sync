#!/bin/bash
# Cloud-Sync Deinstallations-Script
# Entfernt alle installierten Services und Dateien

set -e

echo "=================================="
echo "Cloud-Sync Deinstallation"
echo "=================================="
echo ""

# Prüfe ob als root ausgeführt
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte als root ausführen: sudo ./uninstall.sh"
    exit 1
fi

echo "⚠️  WARNUNG: Diese Aktion wird folgendes entfernen:"
echo "   - Cloud-Sync Service"
echo "   - Web-Dashboard Service"
echo "   - Installierte Dateien in /usr/local/bin/cloud-sync"
echo "   - Systemd Service-Dateien"
echo ""
echo "   Log-Dateien bleiben erhalten:"
echo "   - /var/log/cloud-sync.log"
echo "   - /var/log/cloud-sync-web.log"
echo ""
read -p "Fortfahren? (ja/nein): " confirm

if [ "$confirm" != "ja" ]; then
    echo "Abgebrochen."
    exit 0
fi

echo ""
echo "🛑 Stoppe Services..."
systemctl stop cloud-sync.service 2>/dev/null || true
systemctl stop cloud-sync-web.service 2>/dev/null || true

echo "🗑️  Deaktiviere Services..."
systemctl disable cloud-sync.service 2>/dev/null || true
systemctl disable cloud-sync-web.service 2>/dev/null || true

echo "📁 Entferne Service-Dateien..."
rm -f /etc/systemd/system/cloud-sync.service
rm -f /etc/systemd/system/cloud-sync-web.service

echo "🔄 Systemd neu laden..."
systemctl daemon-reload

echo "📂 Entferne Installations-Verzeichnis..."
rm -rf /usr/local/bin/cloud-sync

echo ""
echo "✅ Deinstallation abgeschlossen!"
echo ""
echo "📝 Log-Dateien wurden NICHT entfernt:"
echo "   /var/log/cloud-sync.log"
echo "   /var/log/cloud-sync-web.log"
echo ""
echo "   Zum manuellen Löschen:"
echo "   sudo rm /var/log/cloud-sync*.log"
echo ""
