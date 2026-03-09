// Cloud-Sync Dashboard JavaScript
// Aktualisiert das Dashboard in Echtzeit durch regelmäßiges Polling der API

let REFRESH_INTERVAL = 10000; // Standard: 10 Sekunden (wird aus API geladen)
const LOG_REFRESH_INTERVAL = 5000; // 5 Sekunden

let statusRefreshTimer = null;
let logRefreshTimer = null;
let countdownTimer = null;
let nextRefreshTime = 0;

// Hilfsfunktionen
function formatTimestamp(isoString) {
    if (!isoString) return '-';
    const date = new Date(isoString);
    return date.toLocaleString('de-DE', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}

function formatRelativeTime(isoString) {
    if (!isoString) return '-';
    const date = new Date(isoString);
    const now = new Date();
    const diffMs = now - date;
    const diffSec = Math.floor(diffMs / 1000);
    
    if (diffSec < 60) return `vor ${diffSec}s`;
    if (diffSec < 3600) return `vor ${Math.floor(diffSec / 60)}m`;
    if (diffSec < 86400) return `vor ${Math.floor(diffSec / 3600)}h`;
    return `vor ${Math.floor(diffSec / 86400)}d`;
}

function formatPath(path) {
    if (!path) return '';
    // Kürze zu lange Pfade
    if (path.length > 60) {
        return '...' + path.substring(path.length - 57);
    }
    return path;
}

// Countdown aktualisieren
function updateCountdown() {
    const now = Date.now();
    const remaining = Math.max(0, nextRefreshTime - now);
    const seconds = Math.ceil(remaining / 1000);
    
    const countdownElement = document.getElementById('next-refresh');
    if (countdownElement) {
        if (seconds > 0) {
            countdownElement.textContent = `in ${seconds}s`;
        } else {
            countdownElement.textContent = 'jetzt...';
        }
    }
}

// Status-Daten abrufen und anzeigen
async function updateStatus() {
    nextRefreshTime = Date.now() + REFRESH_INTERVAL;
    updateCountdown();
    
    try {
        const response = await fetch('/api/status');
        const data = await response.json();
        
        // Service-Informationen
        document.getElementById('service-start').textContent = formatTimestamp(data.service_start);
        document.getElementById('last-update').textContent = formatRelativeTime(data.last_update);
        
        const serviceStatus = document.getElementById('service-status');
        const hasRunningJobs = Object.values(data.jobs).some(job => 
            job.status === 'ready' || job.status === 'syncing' || job.status === 'initializing'
        );
        
        if (hasRunningJobs) {
            serviceStatus.textContent = 'Läuft';
            serviceStatus.className = 'status-badge running';
        } else {
            serviceStatus.textContent = 'Gestoppt';
            serviceStatus.className = 'status-badge error';
        }
        
        // Gesamt-Statistiken
        let totalSyncs = 0;
        let totalErrors = 0;
        
        Object.values(data.jobs).forEach(job => {
            totalSyncs += job.sync_count || 0;
            totalErrors += job.error_count || 0;
        });
        
        document.getElementById('total-jobs').textContent = data.total_jobs;
        document.getElementById('total-syncs').textContent = totalSyncs.toLocaleString('de-DE');
        document.getElementById('total-errors').textContent = totalErrors;
        
        // Refresh-Intervall aus API aktualisieren (falls geändert)
        if (data.refresh_interval && data.refresh_interval * 1000 !== REFRESH_INTERVAL) {
            REFRESH_INTERVAL = data.refresh_interval * 1000;
            console.log(`Refresh-Intervall aktualisiert: ${data.refresh_interval}s`);
            // Timer neu starten mit neuem Intervall
            stopRefreshTimers();
            startRefreshTimers();
            return; // Verhindere doppelte Job-Renderung
        }
        
        // Jobs rendern
        renderJobs(data.jobs);
        
    } catch (error) {
        console.error('Fehler beim Abrufen des Status:', error);
    }
}

// Jobs rendern
function renderJobs(jobs) {
    const container = document.getElementById('jobs-container');
    
    if (Object.keys(jobs).length === 0) {
        container.innerHTML = '<div class="empty-state">Keine Jobs konfiguriert</div>';
        return;
    }
    
    // Sortiere Jobs alphabetisch
    const sortedJobs = Object.values(jobs).sort((a, b) => 
        (a.name || '').localeCompare(b.name || '')
    );
    
    container.innerHTML = sortedJobs.map(job => createJobCard(job)).join('');
}

// Job-Karte erstellen
function createJobCard(job) {
    const params = job.parameters || {};
    const recentSyncs = job.recent_syncs || [];
    
    // Bestimme Status-Klasse basierend auf Job-Status
    let statusClass = 'unknown';
    let statusText = 'Unbekannt';
    
    switch(job.status) {
        case 'syncing':
            statusClass = 'syncing';
            statusText = 'Synchronisiert...';
            break;
        case 'initializing':
            statusClass = 'initializing';
            statusText = 'Initialisierung...';
            break;
        case 'ready':
            statusClass = 'ready';
            statusText = 'Bereit';
            break;
        case 'error':
            statusClass = 'error';
            statusText = 'Fehler';
            break;
        case 'down':
            statusClass = 'down';
            statusText = 'Inaktiv';
            break;
        default:
            statusClass = 'unknown';
            statusText = 'Unbekannt';
    }
    
    return `
        <div class="job-card">
            <div class="job-header">
                <div class="job-title-row">
                    <span class="job-name">${job.name || 'Unbekannt'}</span>
                    <div class="job-header-controls">
                        <div class="job-parameters-inline">
                            <span class="param-badge-compact ${params.new === 'true' ? 'enabled' : 'disabled'}">Neue: ${params.new === 'true' ? '✓' : '✗'}</span>
                            <span class="param-badge-compact ${params.change === 'true' ? 'enabled' : 'disabled'}">Änderungen: ${params.change === 'true' ? '✓' : '✗'}</span>
                            <span class="param-badge-compact ${params.delete === 'true' ? 'enabled' : 'disabled'}">Löschungen: ${params.delete === 'true' ? '✓' : '✗'}</span>
                        </div>
                        <div class="job-status-inline">
                            <span class="job-status-text-compact">${statusText}</span>
                            <span class="job-status-indicator ${statusClass}"></span>
                        </div>
                    </div>
                </div>
                <div class="job-paths-compact">
                    <div class="job-path-compact">📁 ${formatPath(job.source)}</div>
                    <div class="job-path-compact">💾 ${formatPath(job.destination)}</div>
                </div>
            </div>
            <div class="job-body-compact">
                <div class="job-stats-compact">
                    <div class="job-stat-compact">
                        <span class="stat-value-compact">${(job.sync_count || 0).toLocaleString('de-DE')}</span>
                        <span class="stat-label-compact">SYNCHRONISIERT</span>
                    </div>
                    <div class="job-stat-compact">
                        <span class="stat-value-compact">${job.error_count || 0}</span>
                        <span class="stat-label-compact">FEHLER</span>
                    </div>
                    <div class="job-stat-compact">
                        <span class="stat-value-compact">${formatRelativeTime(job.last_activity)}</span>
                        <span class="stat-label-compact">LETZTE AKTIVITÄT</span>
                    </div>
                </div>
                
                ${job.status === 'initializing' ? `
                    <div class="init-info-compact">
                        <div class="init-title">⏳ Initiale Synchronisation läuft...</div>
                        <div class="init-details">
                            ${job.init_files ? `<span>📊 Dateien: ${job.init_files}</span>` : 
                              job.init_files_current ? `<span>📊 Dateien: ${job.init_files_current} (läuft...)</span>` :
                              '<span>📊 Dateien: wird ermittelt...</span>'}
                            ${job.init_size ? `<span>💾 Größe: ${job.init_size}</span>` : 
                              job.init_size_current ? `<span>💾 Größe: ${job.init_size_current} (läuft...)</span>` :
                              '<span>💾 Größe: wird ermittelt...</span>'}
                            ${job.init_transferred ? `<span>📤 Übertragen: ${job.init_transferred}</span>` : ''}
                        </div>
                    </div>
                ` : ''}
                
                ${recentSyncs.length > 0 ? `
                    <div class="recent-syncs-compact">
                        <div class="sync-list">
                            ${recentSyncs.map(sync => createSyncItem(sync)).join('')}
                        </div>
                    </div>
                ` : '<div class="empty-state-compact">Noch keine Synchronisationen</div>'}
            </div>
        </div>
    `;
}

// Sync-Item erstellen
function createSyncItem(sync) {
    const eventClass = sync.event === 'delete' ? 'sync-event-delete' : 'sync-event-sync';
    let icon = '📄';
    let statusBadge = '';
    
    // Event-Icon
    if (sync.event === 'delete') {
        icon = '🗑️';
    } else if (sync.event === 'create') {
        icon = '➕';
    } else if (sync.event === 'modify') {
        icon = '✏️';
    }
    
    // Status-Badge
    if (sync.status === 'success') {
        statusBadge = '<span class="sync-status-badge success">✓</span>';
    } else if (sync.status === 'error') {
        statusBadge = '<span class="sync-status-badge error">✗</span>';
    } else if (sync.status === 'syncing') {
        statusBadge = '<span class="sync-status-badge syncing">⏳</span>';
    }
    
    // Dateiinfo
    let fileInfo = '';
    if (sync.event === 'delete') {
        fileInfo = `${icon} ${sync.file || 'Unbekannt'}`;
    } else {
        const fileName = sync.file || sync.source_file || 'Unbekannt';
        fileInfo = `${icon} ${formatPath(fileName)}`;
    }
    
    // Zusätzliche Info (Größe, Dauer)
    let additionalInfo = [];
    if (sync.size) {
        additionalInfo.push(`📦 ${sync.size}`);
    }
    if (sync.duration) {
        additionalInfo.push(`⏱️ ${sync.duration}`);
    }
    
    return `
        <div class="sync-item ${eventClass}">
            <div class="sync-file-row">
                <div class="sync-file">${fileInfo}</div>
                ${statusBadge}
            </div>
            <div class="sync-meta-row">
                <span class="sync-timestamp">${formatTimestamp(sync.timestamp)}</span>
                ${additionalInfo.length > 0 ? `<span>${additionalInfo.join(' • ')}</span>` : ''}
            </div>
        </div>
    `;
}

// Logs abrufen und anzeigen
async function updateLogs() {
    try {
        const response = await fetch('/api/logs');
        const data = await response.json();
        
        if (data.logs) {
            const logOutput = document.getElementById('log-output');
            // Zeige letzte 50 Zeilen
            const recentLogs = data.logs.slice(-50);
            logOutput.textContent = recentLogs.join('');
            
            // Auto-scroll zum Ende
            const logContainer = logOutput.parentElement;
            logContainer.scrollTop = logContainer.scrollHeight;
        }
    } catch (error) {
        console.error('Fehler beim Abrufen der Logs:', error);
    }
}

// Refresh-Timer starten
function startRefreshTimers() {
    // Initiale Aktualisierung
    updateStatus();
    updateLogs();
    
    // Regelmäßige Aktualisierung
    statusRefreshTimer = setInterval(updateStatus, REFRESH_INTERVAL);
    logRefreshTimer = setInterval(updateLogs, LOG_REFRESH_INTERVAL);
    
    // Countdown-Timer (alle 100ms für flüssige Anzeige)
    countdownTimer = setInterval(updateCountdown, 100);
}

// Refresh-Timer stoppen
function stopRefreshTimers() {
    if (statusRefreshTimer) {
        clearInterval(statusRefreshTimer);
        statusRefreshTimer = null;
    }
    if (logRefreshTimer) {
        clearInterval(logRefreshTimer);
        logRefreshTimer = null;
    }
    if (countdownTimer) {
        clearInterval(countdownTimer);
        countdownTimer = null;
    }
}

// Visibility API: Pausiere Updates wenn Tab nicht sichtbar
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        stopRefreshTimers();
    } else {
        startRefreshTimers();
    }
});

// Beim Laden der Seite starten
document.addEventListener('DOMContentLoaded', () => {
    startRefreshTimers();
});

// Cleanup beim Schließen
window.addEventListener('beforeunload', () => {
    stopRefreshTimers();
});
