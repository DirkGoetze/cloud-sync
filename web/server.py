#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cloud-Sync Web Dashboard
Parst cloud-sync.log in Echtzeit und zeigt Status-Informationen
"""

from flask import Flask, render_template, jsonify
from datetime import datetime
import re
import os
import threading
import time
from collections import defaultdict, deque

app = Flask(__name__)

# Konfiguration - versuche config.py zu laden, sonst Defaults
try:
    from config import WEB_HOST, WEB_PORT, LOG_FILE, CONFIG_FILE, MAX_RECENT_SYNCS
except ImportError:
    # Defaults falls config.py nicht existiert
    WEB_HOST = os.environ.get('WEB_HOST', '0.0.0.0')
    WEB_PORT = int(os.environ.get('WEB_PORT', 8080))
    LOG_FILE = os.environ.get('LOG_FILE', '/usr/local/bin/cloud-sync/log/cloud-sync.log')
    CONFIG_FILE = os.environ.get('CONFIG_FILE', '/usr/local/bin/cloud-sync/conf/cloud-sync.conf')
    MAX_RECENT_SYNCS = int(os.environ.get('MAX_RECENT_SYNCS', 10))

# Web-UI Konfiguration (aus cloud-sync.conf [WEB-UI])
web_ui_config = {
    'refresh_interval': 10  # Standard: 10 Sekunden
}

# Globaler Status-Speicher
status_data = {
    'service_start': datetime.now().isoformat(),
    'jobs': defaultdict(lambda: {
        'name': '',
        'source': '',
        'destination': '',
        'status': 'unknown',  # unknown, ready, initializing, syncing, error, down
        'last_activity': None,
        'sync_count': 0,
        'error_count': 0,
        'recent_syncs': deque(maxlen=MAX_RECENT_SYNCS),
        'parameters': {},
        'init_files': None,
        'init_size': None,
        'init_transferred': None,
        'init_files_current': None,  # Live-Counter während Initialisierung
        'init_size_current': None,   # Live-Größe während Initialisierung
        'init_status': None,
        'is_syncing': False,
        'is_initializing': False
    }),
    'last_update': None,
    'valid_jobs': set()  # Whitelist der gültigen Job-Namen aus Config
}

status_lock = threading.Lock()


def parse_web_ui_config():
    """Parse [WEB-UI] Sektion aus cloud-sync.conf"""
    global web_ui_config
    
    if not os.path.exists(CONFIG_FILE):
        return
    
    in_webui_section = False
    
    try:
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                
                # Prüfe Sektion
                match = re.match(r'^\[([^\]]+)\]', line)
                if match:
                    in_webui_section = (match.group(1) == 'WEB-UI')
                    continue
                
                if in_webui_section:
                    # refresh= Parameter
                    match = re.match(r'refresh\s*=\s*(\d+)', line)
                    if match:
                        web_ui_config['refresh_interval'] = int(match.group(1))
    except Exception as e:
        print(f"Error parsing WEB-UI config: {e}")


def parse_config():
    """Parse cloud-sync.conf um Job-Informationen zu erhalten"""
    jobs = {}
    current_job = None
    
    if not os.path.exists(CONFIG_FILE):
        return jobs
    
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # Job-Name [Section]
            match = re.match(r'^\[([^\]]+)\]', line)
            if match:
                current_job = match.group(1)
                # Ignoriere DEFAULTS und WEB-UI Sections
                if current_job not in ['DEFAULTS', 'WEB-UI']:
                    jobs[current_job] = {
                        'name': current_job,
                        'source': '',
                        'destination': '',
                        'parameters': {}
                    }
                continue
            
            if not current_job or current_job in ['DEFAULTS', 'WEB-UI']:
                continue
            
            # source= Zeile
            match = re.match(r"source\s*=\s*['\"]?([^'\"]+)['\"]?", line)
            if match:
                jobs[current_job]['source'] = match.group(1)
                continue
            
            # destination= Zeile
            match = re.match(r"destination\s*=\s*['\"]?([^'\"]+)['\"]?", line)
            if match:
                jobs[current_job]['destination'] = match.group(1)
                continue
            
            # Parameter (new, change, delete)
            match = re.match(r"(new|change|delete)\s*=\s*(\w+)", line)
            if match:
                jobs[current_job]['parameters'][match.group(1)] = match.group(2)
    
    return jobs


def parse_log_line(line):
    """Parse eine einzelne Log-Zeile"""
    # Neues Format: [2026-03-08 13:31:26] [JobName] [Aktion] Nachricht
    match = re.match(r'\[([^\]]+)\] \[([^\]]+)\] \[([^\]]+)\] (.+)', line)
    if match:
        timestamp_str, job_name, action, message = match.groups()
    else:
        # Fallback: Altes Format [Datum] [JobName] Nachricht (ohne Aktion)
        match = re.match(r'\[([^\]]+)\] \[([^\]]+)\] (.+)', line)
        if not match:
            return None
        timestamp_str, job_name, message = match.groups()
        action = 'INFO'
    
    try:
        timestamp = datetime.strptime(timestamp_str, '%a %b %d %H:%M:%S %Z %Y')
    except:
        try:
            timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
        except:
            timestamp = datetime.now()
    
    return {
        'timestamp': timestamp,
        'job_name': job_name,
        'action': action,
        'message': message,
        'raw': line
    }


def tail_log_file():
    """Tail den Log-File und aktualisiere Status in Echtzeit"""
    print(f"Starting log tail on {LOG_FILE}")
    
    # Parse Web-UI Config
    parse_web_ui_config()
    print(f"Web-UI refresh interval: {web_ui_config['refresh_interval']}s")
    
    # Lade Config
    config_jobs = parse_config()
    with status_lock:
        # Initialisiere Jobs aus Config und erstelle Whitelist
        status_data['valid_jobs'] = set(config_jobs.keys())
        for job_name, job_info in config_jobs.items():
            status_data['jobs'][job_name].update(job_info)
    
    print(f"Valid jobs from config: {status_data['valid_jobs']}")
    
    # Lese initiale Log-Daten (letzte 1000 Zeilen)
    if os.path.exists(LOG_FILE):
        try:
            with open(LOG_FILE, 'r', encoding='utf-8', errors='ignore') as f:
                # Lese letzte 1000 Zeilen
                lines = deque(f, maxlen=1000)
                for line in lines:
                    process_log_line(line.strip())
        except Exception as e:
            print(f"Error reading initial log: {e}")
    
    # Tail den Log-File
    if not os.path.exists(LOG_FILE):
        print(f"Waiting for {LOG_FILE} to be created...")
        while not os.path.exists(LOG_FILE):
            time.sleep(1)
    
    with open(LOG_FILE, 'r', encoding='utf-8', errors='ignore') as f:
        # Gehe zum Ende
        f.seek(0, os.SEEK_END)
        
        while True:
            line = f.readline()
            if line:
                process_log_line(line.strip())
            else:
                time.sleep(0.1)


def process_log_line(line):
    """Verarbeite eine Log-Zeile und aktualisiere Status"""
    if not line:
        return
    
    parsed = parse_log_line(line)
    if not parsed:
        return
    
    job_name = parsed['job_name']
    action = parsed['action']
    message = parsed['message']
    timestamp = parsed['timestamp']
    
    with status_lock:
        # Ignoriere ungültige Job-Namen
        if not job_name or not job_name.strip():
            return
        
        job_name = job_name.strip()
        
        # Ignoriere DEFAULTS und SYSTEM Job-Namen
        if job_name in ['DEFAULTS', 'SYSTEM']:
            if job_name == 'SYSTEM' and action == 'STARTUP':
                status_data['service_start'] = timestamp.isoformat()
            status_data['last_update'] = datetime.now().isoformat()
            return
        
        # WICHTIG: Nur Jobs verarbeiten, die in der Config existieren
        if job_name not in status_data['valid_jobs']:
            print(f"Ignoring log entry for unknown job: '{job_name}'")
            return
        
        job = status_data['jobs'][job_name]
        job['name'] = job_name  # Setze Name explizit
        job['last_activity'] = timestamp.isoformat()
        status_data['last_update'] = datetime.now().isoformat()
        
        # Job-Status basierend auf Aktion
        if action == 'START':
            job['status'] = 'ready'
            job['is_syncing'] = False
            job['is_initializing'] = False
            # Parse source -> target
            match = re.search(r'Überwachung: (.+) -> (.+)', message)
            if match and not job['source']:
                job['source'] = match.group(1)
                job['destination'] = match.group(2)
        
        elif action == 'CONFIG':
            # Parameter extrahieren
            match = re.search(r'new=(\w+), change=(\w+), delete=(\w+)', message)
            if match:
                job['parameters'] = {
                    'new': match.group(1),
                    'change': match.group(2),
                    'delete': match.group(3)
                }
        
        elif action == 'INIT':
            # Initiale Sync - extrahiere Statistiken
            job['status'] = 'initializing'
            job['is_initializing'] = True
            job['is_syncing'] = False
            
            if 'Number of files' in message:
                match = re.search(r'Number of files[^:]*:\s*([\d,]+)', message)
                if match:
                    job['init_files'] = match.group(1).replace(',', '')
            elif 'Total file size' in message:
                match = re.search(r'Total file size:\s*([\d.,]+)\s*(\w+)', message)
                if match:
                    job['init_size'] = f"{match.group(1)} {match.group(2)}"
            elif 'Total transferred' in message:
                match = re.search(r'Total transferred[^:]*:\s*([\d.,]+)\s*(\w+)', message)
                if match:
                    job['init_transferred'] = f"{match.group(1)} {match.group(2)}"
        
        elif action == 'PROGRESS':
            # Live-Fortschritt während initialer Sync
            # Format: Dateien: 543, Größe: 234.56 MB
            job['status'] = 'initializing'
            job['is_initializing'] = True
            
            # Parse Dateianzahl
            match_files = re.search(r'Dateien:\s*(\d+)', message)
            if match_files:
                job['init_files_current'] = match_files.group(1)
            
            # Parse Größe (akzeptiere sowohl Punkt als auch Komma als Dezimaltrennzeichen)
            match_size = re.search(r'Größe:\s*([\d.,]+)\s*(\w+)', message)
            if match_size:
                job['init_size_current'] = f"{match_size.group(1)} {match_size.group(2)}"
        
        elif action == 'SYNC':
            # Sync-Event - extrahiere Dateiname und Größe
            if 'CREATE' in message or 'MODIFY' in message or 'MOVED_TO' in message:
                # Format: CREATE: filename.ext (1.23MB)
                match = re.search(r'(CREATE|MODIFY|MOVED_TO):\s*([^(]+)\s*\(([^)]+)\)', message)
                if match:
                    event_type, filename, size = match.groups()
                    job['sync_count'] += 1
                    job['status'] = 'syncing'
                    job['is_syncing'] = True
                    job['is_initializing'] = False
                    job['recent_syncs'].appendleft({
                        'timestamp': timestamp.isoformat(),
                        'file': filename.strip(),
                        'size': size.strip(),
                        'event': event_type.lower(),
                        'status': 'syncing'
                    })
        
        elif action == 'DELETE':
            # Lösch-Event
            if 'Lösche:' in message:
                match = re.search(r'Lösche:\s*(.+)', message)
                if match:
                    filename = match.group(1).strip()
                    job['status'] = 'syncing'
                    job['is_syncing'] = True
                    job['is_initializing'] = False
                    job['recent_syncs'].appendleft({
                        'timestamp': timestamp.isoformat(),
                        'file': filename,
                        'event': 'delete',
                        'status': 'deleting'
                    })
        
        elif action == 'SUCCESS':
            # Erfolgreiche Operation - extrahiere Dauer
            if 'synchronisiert in' in message:
                match = re.search(r'synchronisiert in (\d+)s', message)
                if match:
                    duration = int(match.group(1))
                    # Update letzter Sync in recent_syncs
                    if job['recent_syncs']:
                        job['recent_syncs'][0]['status'] = 'success'
                        job['recent_syncs'][0]['duration'] = f"{duration}s"
                    # Zurück zu ready-Status
                    job['status'] = 'ready'
                    job['is_syncing'] = False
            elif 'Initiale Synchronisation erfolgreich' in message:
                job['init_status'] = 'success'
                job['status'] = 'ready'
                job['is_initializing'] = False
            elif 'Löschung erfolgreich' in message:
                if job['recent_syncs']:
                    job['recent_syncs'][0]['status'] = 'success'
                job['status'] = 'ready'
                job['is_syncing'] = False
        
        elif action == 'FEHLER':
            # Fehler
            job['error_count'] += 1
            job['status'] = 'error'
            
            # Update recent_syncs mit Fehler-Status
            if job['recent_syncs'] and 'Rsync fehlgeschlagen' in message:
                job['recent_syncs'][0]['status'] = 'error'
            elif 'Initiale Synchronisation fehlgeschlagen' in message:
                job['init_status'] = 'error'
            elif 'Löschung fehlgeschlagen' in message:
                if job['recent_syncs']:
                    job['recent_syncs'][0]['status'] = 'error'
        
        elif action == 'WARNUNG':
            # Warnungen
            if 'Keine Sync-Events aktiviert' in message:
                job['status'] = 'down'
            
        # Auto-Timeout: Wenn länger als 30 Sekunden keine Aktivität, setze auf ready
        if job['last_activity']:
            try:
                last_activity_time = datetime.fromisoformat(job['last_activity'])
                time_diff = (timestamp - last_activity_time).total_seconds()
                if time_diff > 30 and job['status'] == 'syncing':
                    job['status'] = 'ready'
                    job['is_syncing'] = False
            except:
                pass


@app.route('/')
def dashboard():
    """Haupt-Dashboard"""
    return render_template('dashboard.html')


@app.route('/api/status')
def get_status():
    """API: Aktueller Status aller Jobs"""
    with status_lock:
        # Konvertiere defaultdict zu regulärem dict und deque zu list
        # Filtere Jobs ohne source/destination und ungültige Jobs
        jobs_data = {}
        for job_name, job_info in status_data['jobs'].items():
            # Überspringe Jobs mit leerem Namen
            if not job_name or not job_name.strip():
                continue
            
            # Überspringe System-Jobs
            if job_name in ['DEFAULTS', 'SYSTEM']:
                continue
            
            # Überspringe Jobs ohne source oder destination
            if not job_info.get('source') or not job_info.get('destination'):
                continue
            
            jobs_data[job_name] = {
                'name': job_info['name'],
                'source': job_info['source'],
                'destination': job_info['destination'],
                'status': job_info['status'],
                'last_activity': job_info['last_activity'],
                'sync_count': job_info['sync_count'],
                'error_count': job_info['error_count'],
                'recent_syncs': list(job_info['recent_syncs']),
                'parameters': job_info['parameters'],
                'init_files': job_info['init_files'],
                'init_size': job_info['init_size'],
                'init_transferred': job_info['init_transferred'],
                'init_status': job_info['init_status'],
                'is_syncing': job_info['is_syncing'],
                'is_initializing': job_info['is_initializing']
            }
        
        return jsonify({
            'service_start': status_data['service_start'],
            'last_update': status_data['last_update'],
            'jobs': jobs_data,
            'total_jobs': len(jobs_data),
            'refresh_interval': web_ui_config['refresh_interval']
        })


@app.route('/api/logs')
def get_logs():
    """API: Letzte Log-Zeilen"""
    try:
        with open(LOG_FILE, 'r', encoding='utf-8', errors='ignore') as f:
            lines = deque(f, maxlen=100)
            return jsonify({
                'logs': list(lines),
                'count': len(lines)
            })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def main():
    # Starte Log-Tail in separatem Thread
    log_thread = threading.Thread(target=tail_log_file, daemon=True)
    log_thread.start()
    
    # Starte Flask-Server
    print(f"Starting Cloud-Sync Web Dashboard on http://{WEB_HOST}:{WEB_PORT}")
    app.run(host=WEB_HOST, port=WEB_PORT, debug=False, threaded=True)


if __name__ == '__main__':
    main()
