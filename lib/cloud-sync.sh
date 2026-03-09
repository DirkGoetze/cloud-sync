#!/bin/bash
# filepath: /usr/local/bin/cloud-sync/lib/cloud-sync.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../conf/cloud-sync.conf"
LOG_FILE="$SCRIPT_DIR/../log/cloud-sync.log"

# Funktion zum Parsen der INI-Datei
parse_config() {
    local current_job=""
    local source=""
    local destination=""
    local job_new=""
    local job_change=""
    local job_delete=""
    
    # Globale Defaults
    local default_new="true"
    local default_change="true"
    local default_delete="false"
    
    while IFS= read -r line; do
        # Leerzeilen und Kommentare überspringen
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Job-Name [Section]
        if [[ "$line" =~ ^\[([^]]+)\] ]]; then
            # Vorherigen Job verarbeiten (aber nicht DEFAULTS)
            if [[ -n "$current_job" && "$current_job" != "DEFAULTS" && -n "$source" && -n "$destination" ]]; then
                # Verwende Job-Werte oder falle auf Defaults zurück
                local final_new="${job_new:-$default_new}"
                local final_change="${job_change:-$default_change}"
                local final_delete="${job_delete:-$default_delete}"
                echo "$current_job|$source|$destination|$final_new|$final_change|$final_delete"
            fi
            
            current_job="${BASH_REMATCH[1]}"
            source=""
            destination=""
            job_new=""
            job_change=""
            job_delete=""
            continue
        fi
        
        # source= Zeile
        if [[ "$line" =~ ^[[:space:]]*source[[:space:]]*=[[:space:]]*[\'\"]?([^\'\"]+)[\'\"]?[[:space:]]*$ ]]; then
            source="${BASH_REMATCH[1]}"
            continue
        fi
        
        # destination= Zeile
        if [[ "$line" =~ ^[[:space:]]*destination[[:space:]]*=[[:space:]]*[\'\"]?([^\'\"]+)[\'\"]?[[:space:]]*$ ]]; then
            destination="${BASH_REMATCH[1]}"
            continue
        fi
        
        # new= Zeile
        if [[ "$line" =~ ^[[:space:]]*new[[:space:]]*=[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
            if [[ "$current_job" == "DEFAULTS" ]]; then
                default_new="${BASH_REMATCH[1]}"
            else
                job_new="${BASH_REMATCH[1]}"
            fi
            continue
        fi
        
        # change= Zeile
        if [[ "$line" =~ ^[[:space:]]*change[[:space:]]*=[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
            if [[ "$current_job" == "DEFAULTS" ]]; then
                default_change="${BASH_REMATCH[1]}"
            else
                job_change="${BASH_REMATCH[1]}"
            fi
            continue
        fi
        
        # delete= Zeile
        if [[ "$line" =~ ^[[:space:]]*delete[[:space:]]*=[[:space:]]*([^[:space:]]+)[[:space:]]*$ ]]; then
            if [[ "$current_job" == "DEFAULTS" ]]; then
                default_delete="${BASH_REMATCH[1]}"
            else
                job_delete="${BASH_REMATCH[1]}"
            fi
            continue
        fi
    done < "$CONFIG_FILE"
    
    # Letzten Job nicht vergessen (aber nicht DEFAULTS)
    if [[ -n "$current_job" && "$current_job" != "DEFAULTS" && -n "$source" && -n "$destination" ]]; then
        local final_new="${job_new:-$default_new}"
        local final_change="${job_change:-$default_change}"
        local final_delete="${job_delete:-$default_delete}"
        echo "$current_job|$source|$destination|$final_new|$final_change|$final_delete"
    fi
}

# Funktion für einzelnes Sync-Paar
watch_and_sync() {
    local JOB_NAME="$1"
    local SOURCE="$2"
    local TARGET="$3"
    local SYNC_NEW="$4"
    local SYNC_CHANGE="$5"
    local SYNC_DELETE="$6"
    
    echo "[$(date)] [$JOB_NAME] [START] Starte Überwachung: $SOURCE -> $TARGET" >> "$LOG_FILE"
    echo "[$(date)] [$JOB_NAME] [CONFIG] Parameter: new=$SYNC_NEW, change=$SYNC_CHANGE, delete=$SYNC_DELETE" >> "$LOG_FILE"
    
    # Baue rsync Optionen für initiale Synchronisation
    local RSYNC_OPTS="-av"
    
    # Logik für new/change Kombination:
    # new=true,  change=true  → Standard (-av): Neue + Änderungen
    # new=true,  change=false → --ignore-existing: Nur neue Dateien
    # new=false, change=true  → --existing: Nur Updates, keine neuen
    # new=false, change=false → Keine initiale Sync
    
    if [[ "$SYNC_NEW" == "true" && "$SYNC_CHANGE" == "false" ]]; then
        RSYNC_OPTS="$RSYNC_OPTS --ignore-existing"
    elif [[ "$SYNC_NEW" == "false" && "$SYNC_CHANGE" == "true" ]]; then
        RSYNC_OPTS="$RSYNC_OPTS --existing"
    elif [[ "$SYNC_NEW" == "false" && "$SYNC_CHANGE" == "false" ]]; then
        echo "[$(date)] [$JOB_NAME] [INFO] Keine initiale Synchronisation (new=false, change=false)" >> "$LOG_FILE"
        RSYNC_OPTS=""
    fi
    
    [[ "$SYNC_DELETE" == "true" ]] && RSYNC_OPTS="$RSYNC_OPTS --delete"
    
    # Initiale Synchronisation mit Stats
    if [[ -n "$RSYNC_OPTS" ]]; then
        echo "[$(date)] [$JOB_NAME] [INIT] Starte initiale Synchronisation..." >> "$LOG_FILE"
        
        # Verwende --info=progress2 für Live-Fortschritt und --stats für finale Zusammenfassung
        RSYNC_OPTS_PROGRESS="${RSYNC_OPTS//-v/} --info=progress2 --stats"
        
        # Führe rsync aus und logge Fortschritt + Stats
        # xfr# = Fortschrittszeilen, rest = finale Stats
        rsync $RSYNC_OPTS_PROGRESS "$SOURCE/" "$TARGET/" 2>&1 | \
            grep -E "xfr#|ir-chk|to-chk|Number of files|Total file size|Total transferred|speedup" | \
            while IFS= read -r line; do
                # Fortschrittszeilen (xfr#) nur alle 100 Transfers loggen, um Log nicht zu überfluten
                if [[ "$line" =~ xfr#([0-9]+) ]]; then
                    XFR_NUM="${BASH_REMATCH[1]}"
                    # Logge nur bei jedem 100. Transfer oder wenn Zahl auf 00 endet
                    if [[ $((XFR_NUM % 100)) -eq 0 ]] || [[ "$XFR_NUM" =~ 00$ ]]; then
                        echo "[$(date)] [$JOB_NAME] [PROGRESS] $line" >> "$LOG_FILE"
                    fi
                else
                    # Stats und finale Zeilen immer loggen
                    echo "[$(date)] [$JOB_NAME] [INIT] $line" >> "$LOG_FILE"
                fi
            done
        
        # Prüfe Exit-Code (pipe status vom rsync)
        RSYNC_EXIT=${PIPESTATUS[0]}
        if [ $RSYNC_EXIT -eq 0 ]; then
            echo "[$(date)] [$JOB_NAME] [SUCCESS] Initiale Synchronisation erfolgreich abgeschlossen" >> "$LOG_FILE"
        else
            echo "[$(date)] [$JOB_NAME] [FEHLER] Initiale Synchronisation fehlgeschlagen (Exit: $RSYNC_EXIT)" >> "$LOG_FILE"
        fi
    fi
    
    # Baue inotifywait Events
    local EVENTS=""
    [[ "$SYNC_NEW" == "true" ]] && EVENTS="create,moved_to"
    [[ "$SYNC_CHANGE" == "true" ]] && EVENTS="${EVENTS:+$EVENTS,}modify"
    [[ "$SYNC_DELETE" == "true" ]] && EVENTS="${EVENTS:+$EVENTS,}delete,moved_from"
    
    # Wenn keine Events aktiviert sind, beende die Funktion
    if [[ -z "$EVENTS" ]]; then
        echo "[$(date)] [$JOB_NAME] [WARNUNG] Keine Sync-Events aktiviert!" >> "$LOG_FILE"
        return
    fi
    
    echo "[$(date)] [$JOB_NAME] [START] Starte Live-Überwachung für Events: $EVENTS" >> "$LOG_FILE"
    
    # Überwachung (mit -q für quiet, ohne Statusmeldungen)
    inotifywait -m -r -q -e "$EVENTS" "$SOURCE" --format '%e %w%f' 2>&1 |
    while read EVENT FILE
    do
        # Debug: Logge empfangenes Event
        echo "[$(date)] [$JOB_NAME] [DEBUG] Event empfangen: EVENT=$EVENT FILE=$FILE" >> "$LOG_FILE"
        
        RELATIVE_PATH="${FILE#$SOURCE/}"
        TARGET_FILE="$TARGET/$RELATIVE_PATH"
        TARGET_DIR=$(dirname "$TARGET_FILE")
        
        # Löschungen behandeln
        if [[ "$EVENT" == "DELETE" || "$EVENT" == "MOVED_FROM" ]]; then
            if [[ "$SYNC_DELETE" == "true" ]]; then
                FILENAME=$(basename "$TARGET_FILE")
                echo "[$(date)] [$JOB_NAME] [DELETE] Lösche: $FILENAME" >> "$LOG_FILE"
                
                if rm -rf "$TARGET_FILE" 2>&1 | while IFS= read -r line; do
                    echo "[$(date)] [$JOB_NAME] [DELETE] $line" >> "$LOG_FILE"
                done; [ ${PIPESTATUS[0]} -eq 0 ]; then
                    echo "[$(date)] [$JOB_NAME] [SUCCESS] Löschung erfolgreich" >> "$LOG_FILE"
                else
                    echo "[$(date)] [$JOB_NAME] [FEHLER] Löschung fehlgeschlagen" >> "$LOG_FILE"
                fi
            fi
        else
            # Neue Dateien oder Änderungen
            mkdir -p "$TARGET_DIR"
            
            # Verwende job-spezifische rsync Optionen
            local FILE_RSYNC_OPTS="-av"
            if [[ "$EVENT" =~ CREATE|MOVED_TO ]] && [[ "$SYNC_NEW" != "true" ]]; then
                continue  # Überspringe wenn new=false
            fi
            if [[ "$EVENT" =~ MODIFY ]] && [[ "$SYNC_CHANGE" != "true" ]]; then
                continue  # Überspringe wenn change=false
            fi
            
            # Ermittle Dateigröße und Name
            FILENAME=$(basename "$FILE")
            FILESIZE=$(stat -c%s "$FILE" 2>/dev/null || echo "unknown")
            if [ "$FILESIZE" != "unknown" ]; then
                FILESIZE_MB=$(awk "BEGIN {printf \"%.2f\", $FILESIZE/1024/1024}")
                SIZE_INFO="${FILESIZE_MB}MB"
            else
                SIZE_INFO="unknown size"
            fi
            
            # Log Start
            echo "[$(date)] [$JOB_NAME] [SYNC] $EVENT: $FILENAME ($SIZE_INFO)" >> "$LOG_FILE"
            
            # Starte Timer
            START_TIME=$(date +%s)
            
            # Rsync mit Ausgabe-Präfix
            rsync $FILE_RSYNC_OPTS "$FILE" "$TARGET_FILE" 2>&1 | while IFS= read -r line; do
                echo "[$(date)] [$JOB_NAME] [SYNC] $line" >> "$LOG_FILE"
            done
            
            # Prüfe Exit-Code und logge Ergebnis
            RSYNC_EXIT=${PIPESTATUS[0]}
            if [ $RSYNC_EXIT -eq 0 ]; then
                END_TIME=$(date +%s)
                DURATION=$((END_TIME - START_TIME))
                echo "[$(date)] [$JOB_NAME] [SUCCESS] Datei synchronisiert in ${DURATION}s" >> "$LOG_FILE"
            else
                echo "[$(date)] [$JOB_NAME] [FEHLER] Rsync fehlgeschlagen (Exit: $RSYNC_EXIT)" >> "$LOG_FILE"
            fi
        fi
    done
}

# Cleanup
cleanup() {
    echo "[$(date)] [SYSTEM] [SHUTDOWN] Stoppe Cloud-Sync Service (alle Jobs)" >> "$LOG_FILE"
    kill $(jobs -p) 2>/dev/null
    exit 0
}

trap cleanup SIGTERM SIGINT

# Pr�fe ob Konfigurationsdatei existiert
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[$(date)] [SYSTEM] [FEHLER] Konfigurationsdatei nicht gefunden: $CONFIG_FILE" >> "$LOG_FILE"
    exit 1
fi

# Log-Datei initialisieren
echo "[$(date)] [SYSTEM] [STARTUP] ====== Cloud-Sync Service gestartet ======" >> "$LOG_FILE"

# Konfiguration einlesen und Prozesse starten
JOBS_STARTED=0
while IFS='|' read -r JOB_NAME SOURCE DESTINATION SYNC_NEW SYNC_CHANGE SYNC_DELETE; do
    # Prüfe ob Quellordner existiert
    if [ ! -d "$SOURCE" ]; then
        echo "[$(date)] [$JOB_NAME] [FEHLER] Quellordner nicht gefunden: $SOURCE" >> "$LOG_FILE"
        continue
    fi
    
    # Erstelle Zielordner falls nicht vorhanden
    mkdir -p "$DESTINATION"
    
    # Starte Sync-Prozess im Hintergrund
    watch_and_sync "$JOB_NAME" "$SOURCE" "$DESTINATION" "$SYNC_NEW" "$SYNC_CHANGE" "$SYNC_DELETE" &
    JOBS_STARTED=$((JOBS_STARTED + 1))
    
done < <(parse_config)

if [ $JOBS_STARTED -eq 0 ]; then
    echo "[$(date)] [SYSTEM] [WARNUNG] Keine gültigen Sync-Jobs gefunden!" >> "$LOG_FILE"
    exit 1
fi

echo "[$(date)] [SYSTEM] [STARTUP] $JOBS_STARTED Sync-Job(s) gestartet" >> "$LOG_FILE"
wait