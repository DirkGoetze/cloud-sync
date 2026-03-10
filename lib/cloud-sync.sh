#!/bin/bash
# filepath: /usr/local/bin/cloud-sync/lib/cloud-sync.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ***************************************************************************
# BEGIN: LOG Handling
# ***************************************************************************

# ===========================================================================
# Konstanten für das Log-Handling
# ===========================================================================
#-- Pfad zur Log-Datei ------------------------------------------------------
LOG_FILE="$SCRIPT_DIR/../log/cloud-sync.log"
#-- Log-Levels definieren ---------------------------------------------------
LOG_LEVEL_INFO="INFO"
LOG_LEVEL_ERROR="FEHLER"
LOG_LEVEL_SUCCESS="SUCCESS"
LOG_LEVEL_WARNING="WARNUNG"
LOG_LEVEL_DEBUG="DEBUG"
LOG_LEVEL_START="START"
LOG_LEVEL_STARTUP="STARTUP"
LOG_LEVEL_SHUTDOWN="SHUTDOWN"
LOG_LEVEL_CONFIG="CONFIG"
LOG_LEVEL_INIT="INIT"
LOG_LEVEL_PROGRESS="PROGRESS"
LOG_LEVEL_DELETE="DELETE"
LOG_LEVEL_SYNC="SYNC"

# ===========================================================================
# _set_log
# ---------------------------------------------------------------------------
# Function.: write message to log file with timestamp
# Parameter: level = log level (INFO, ERROR, etc.)
# .........  category = SYSTEM or job name 
# .........  message = log message to write
# Return...: 0 on success, 1 on failure
# ===========================================================================
_set_log() {
    #-- Define local variables ----------------------------------------------
    local level="$1"
    local category="$2"
    local message="$3"

    #-- Validate parameters -------------------------------------------------
    if [[ -z "$category" || -z "$level" || -z "$message" ]]; then
        echo "Error: Category, level and message must be provided" >&2
        return 1
    fi

    #-- Write log message with timestamp ------------------------------------
    echo "[$(date)] [$category] [$level] $message" >> "$LOG_FILE"

    #-- Return success ------------------------------------------------------
    return 0
}

# ===========================================================================
# log_info
# ---------------------------------------------------------------------------
# Function.: Write INFO level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_info() {
    #-- Call _set_log with INFO level ---------------------------------------
    _set_log "$LOG_LEVEL_INFO" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_error
# ---------------------------------------------------------------------------
# Function.: Write FEHLER level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_error() {
    #-- Call _set_log with FEHLER level -------------------------------------
    _set_log "$LOG_LEVEL_ERROR" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_success
# ---------------------------------------------------------------------------
# Function.: Write SUCCESS level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_success() {
    #-- Call _set_log with SUCCESS level ------------------------------------
    _set_log "$LOG_LEVEL_SUCCESS" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_warning
# ---------------------------------------------------------------------------
# Function.: Write WARNUNG level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_warning() {
    #-- Call _set_log with WARNUNG level ------------------------------------
    _set_log "$LOG_LEVEL_WARNING" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_debug
# ---------------------------------------------------------------------------
# Function.: Write DEBUG level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_debug() {
    #-- Call _set_log with DEBUG level --------------------------------------
    _set_log "$LOG_LEVEL_DEBUG" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_start
# ---------------------------------------------------------------------------
# Function.: Write START level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_start() {
    #-- Call _set_log with START level --------------------------------------
    _set_log "$LOG_LEVEL_START" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_startup
# ---------------------------------------------------------------------------
# Function.: Write STARTUP level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_startup() {
    #-- Call _set_log with STARTUP level ------------------------------------
    _set_log "$LOG_LEVEL_STARTUP" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_shutdown
# ---------------------------------------------------------------------------
# Function.: Write SHUTDOWN level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_shutdown() {
    #-- Call _set_log with SHUTDOWN level -----------------------------------
    _set_log "$LOG_LEVEL_SHUTDOWN" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_config
# ---------------------------------------------------------------------------
# Function.: Write CONFIG level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_config() {
    #-- Call _set_log with CONFIG level -------------------------------------
    _set_log "$LOG_LEVEL_CONFIG" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_init
# ---------------------------------------------------------------------------
# Function.: Write INIT level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_init() {
    #-- Call _set_log with INIT level ---------------------------------------
    _set_log "$LOG_LEVEL_INIT" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_progress
# ---------------------------------------------------------------------------
# Function.: Write PROGRESS level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_progress() {
    #-- Call _set_log with PROGRESS level -----------------------------------
    _set_log "$LOG_LEVEL_PROGRESS" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_delete
# ---------------------------------------------------------------------------
# Function.: Write DELETE level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_delete() {
    #-- Call _set_log with DELETE level -------------------------------------
    _set_log "$LOG_LEVEL_DELETE" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ===========================================================================
# log_sync
# ---------------------------------------------------------------------------
# Function.: Write SYNC level log entry
# Parameter: category = SYSTEM or job name
# .........  message = log message
# Return...: 0 on success, 1 on failure
# ===========================================================================
log_sync() {
    #-- Call _set_log with SYNC level ---------------------------------------
    _set_log "$LOG_LEVEL_SYNC" "$1" "$2"
    #-- Return success ------------------------------------------------------
    return $?
}

# ***************************************************************************
# END: LOG Handling
# ***************************************************************************

# ***************************************************************************
# BEGIN: INI Handling
# ***************************************************************************

#-- Pfad zur Konfigurationsdatei --------------------------------------------
CONFIG_FILE="$SCRIPT_DIR/../conf/cloud-sync.conf"

# ===========================================================================
# get_file_ini
# ---------------------------------------------------------------------------
# Function.: return path to INI file
# Parameter: none
# Return...: path to INI file
# ===========================================================================
get_file_ini() {
    #-- Lokale Variablen definieren -----------------------------------------
    local file="$CONFIG_FILE"

    #-- Prüfen ob Datei existiert -------------------------------------------
    if [ ! -f "$file" ]; then
        echo "Error: INI file not found: $file" >&2
        return 1
    fi

    #-- Prüfen ob Datei lesbar/beschreibar ist ------------------------------
    if [ ! -w "$file" ] && [ ! -r "$file" ]; then
        echo "Error: INI file is not readable/writable: $file" >&2
        return 1
    fi

    #-- Pfad zur INI-Datei zurückgeben --------------------------------------
    echo "$file"
    return 0
}

# ===========================================================================
# get_value_ini
# ---------------------------------------------------------------------------
# Function.: read value from INI file, supports section and key with optional
# .........  default value, sets the default value if key is not found
# Parameter: section = section name in INI file
# .........  key = value to read
# .........  default = optional default value 
# Return...: value
# ===========================================================================
get_value_ini() {
    #-- Read parameters -----------------------------------------------------
    local section="$1"
    local key="$2"
    local default="$3"

    #-- Define local variables ----------------------------------------------
    local file="$(get_file_ini)"
    
    #-- Validate parameters -------------------------------------------------
    if [[ -z "$section" || -z "$key" ]]; then
        echo "Error: Section and key must be provided" >&2
        return 1
    fi

    #-- Parse file and return found value -----------------------------------
    local value=""
    value=$(awk -F'=' -v section="$section" -v key="$key" '
        $0 ~ "\\[" section "\\]" { in_section=1; next }
        $0 ~ "^\\[" { in_section=0 }
        in_section && $1 ~ "^" key "[[:space:]]*$" {
            gsub(/^[ \t]+|[ \t]+$/, "", $2)  # Trim whitespace
            print $2
            exit
        }
    ' "$file")
    
    #-- If no value found, use default --------------------------------------
    if [[ -z "$value" ]]; then
        set_value_ini "$section" "$key" "$default" >/dev/null 2>&1
        value="$default"
    fi

    #-- Return value --------------------------------------------------------
    echo "$value"
    return 0
}

# ===========================================================================
# set_value_ini
# ---------------------------------------------------------------------------
# Function.: write value to INI file
# Parameter: section
# .........  key
# .........  value
# Return...: none
# ===========================================================================
set_value_ini() {
    #-- Parameter lesen -----------------------------------------------------
    local section="$1"
    local key="$2"
    local value="$3"

    #-- Lokale Variablen definieren -----------------------------------------
    local file="$(get_file_ini)"

    #-- Parameter validieren ------------------------------------------------
    if [[ -z "$section" || -z "$key" ]]; then
        echo "Error: Section and key must be provided" >&2
        return 1
    fi

    #-- Datei parsen und Wert setzen ----------------------------------------
    awk -F'=' -v section="$section" -v key="$key" -v value="$value" '
        BEGIN { in_section=0; updated=0 }
        $0 ~ "\\[" section "\\]" { in_section=1; print; next }
        $0 ~ "^\\[" { in_section=0 }
        in_section && $1 ~ "^" key "[[:space:]]*$" {
            print key " = " value
            updated=1
            next
        }
        { print }
        END {
            if (!updated) {
                if (!in_section) {
                    print "[" section "]"
                }
                print key " = " value
            }
        }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

    #-- Erfolg zurückgeben --------------------------------------------------
    return 0
}

# ===========================================================================
# get_sections_ini
# ---------------------------------------------------------------------------
# Function.: get all section names from INI file
# Parameter: none
# Return...: list of section names (one per line)
# ===========================================================================
get_sections_ini() {
    #-- Lokale Variablen definieren -----------------------------------------
    local file="$(get_file_ini)"
    
    #-- Alle Sektionen extrahieren ------------------------------------------
    awk '
        /^\[.*\]/ {
            gsub(/^\[|\]$/, "")
            print
        }
    ' "$file"
}

# ***************************************************************************
# END: INI Handling
# ***************************************************************************

# ===========================================================================
# parse_config
# ---------------------------------------------------------------------------
# Function.: parse INI file and return job configurations
# Parameter: none
# Return...: job configurations in format: name|source|dest|new|change|delete
# ===========================================================================
parse_config() {
    #-- Read defaults from DEFAULTS section with fallback values ------------
    local default_new="$(get_value_ini "DEFAULTS" "new" "true")"
    local default_change="$(get_value_ini "DEFAULTS" "change" "true")"
    local default_delete="$(get_value_ini "DEFAULTS" "delete" "false")"
    
    #-- Iterate through all sections ----------------------------------------
    while IFS= read -r section; do
        #-- Skip DEFAULTS and WEB-UI sections -------------------------------
        [[ "$section" == "DEFAULTS" || "$section" == "WEB-UI" ]] && continue
        
        #-- Read job data using INI functions -------------------------------
        local source="$(get_value_ini "$section" "source")"
        local destination="$(get_value_ini "$section" "destination")"
        
        #-- Only process jobs with source and destination -------------------
        if [[ -n "$source" && -n "$destination" ]]; then
            #-- Read job-specific values with default fallback --------------
            local final_new="$(get_value_ini "$section" "new" "$default_new")"
            local final_change="$(get_value_ini "$section" "change" "$default_change")"
            local final_delete="$(get_value_ini "$section" "delete" "$default_delete")"
            
            #-- Output job configuration ------------------------------------
            echo "$section|$source|$destination|$final_new|$final_change|$final_delete"
        fi
    done < <(get_sections_ini)
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
        
        # Führe rsync mit custom output format für Größen-Tracking
        RSYNC_OPTS_INIT="$RSYNC_OPTS --stats --out-format=%l|%n"
        
        # Zähler für Dateien und Größe
        FILE_COUNT=0
        TOTAL_BYTES=0
        LAST_LOG_TIME=$(date +%s)
        
        # Hilfsfunktion für lesbare Größen
        format_size() {
            local bytes=$1
            if [[ $bytes -lt 1024 ]]; then
                echo "$bytes Bytes"
            elif [[ $bytes -lt 1048576 ]]; then
                echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
            elif [[ $bytes -lt 1073741824 ]]; then
                echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
            elif [[ $bytes -lt 1099511627776 ]]; then
                echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
            else
                echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1099511627776}") TB"
            fi
        }
        
        # Führe rsync aus und parse Output (Process Substitution vermeidet Subshell)
        while IFS='|' read -r size filename; do
            # Überspringe Leerzeilen und Stats
            [[ -z "$size" ]] && continue
            
            # Wenn Zeile das Format "Zahl|Dateiname" hat
            if [[ "$size" =~ ^[0-9]+$ ]]; then
                ((FILE_COUNT++))
                TOTAL_BYTES=$((TOTAL_BYTES + size))
                
                # Logge Fortschritt alle 10 Sekunden ODER alle 100 Dateien
                CURRENT_TIME=$(date +%s)
                TIME_DIFF=$((CURRENT_TIME - LAST_LOG_TIME))
                
                if [[ $TIME_DIFF -ge 10 ]] || [[ $((FILE_COUNT % 100)) -eq 0 ]]; then
                    FORMATTED_SIZE=$(format_size $TOTAL_BYTES)
                    echo "[$(date)] [$JOB_NAME] [PROGRESS] Dateien: $FILE_COUNT, Größe: $FORMATTED_SIZE" >> "$LOG_FILE"
                    LAST_LOG_TIME=$CURRENT_TIME
                fi
            # Stats-Zeilen (ohne Pipe)
            elif [[ "$size" =~ (Number of files|Total file size|Total transferred|speedup) ]]; then
                echo "[$(date)] [$JOB_NAME] [INIT] $size" >> "$LOG_FILE"
            fi
        done < <(rsync $RSYNC_OPTS_INIT "$SOURCE/" "$TARGET/" 2>&1)
        
        # Prüfe Exit-Code
        RSYNC_EXIT=$?
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
            FILESIZE=$(stat -c%s "$FILE" 2>/dev/null || echo "unknown")
            if [ "$FILESIZE" != "unknown" ]; then
                FILESIZE_MB=$(awk "BEGIN {printf \"%.2f\", $FILESIZE/1024/1024}")
                SIZE_INFO="${FILESIZE_MB}MB"
            else
                SIZE_INFO="unknown size"
            fi
            
            # Log Start mit relativem Pfad
            echo "[$(date)] [$JOB_NAME] [SYNC] $EVENT: $RELATIVE_PATH ($SIZE_INFO)" >> "$LOG_FILE"
            
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

# Prüfe ob Konfigurationsdatei existiert und lesbar ist
if ! config_file="$(get_file_ini 2>&1)"; then
    echo "[$(date)] [SYSTEM] [FEHLER] $config_file" >> "$LOG_FILE"
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