# WICHTIG: Datei-Encoding für Cloud-Sync

## Für alle Bash-Scripts (.sh Dateien)

**ZWINGEND erforderlich:**
- ✅ Encoding: **UTF-8** (OHNE BOM)
- ✅ Zeilenumbrüche: **LF** (Linux)

**NICHT verwenden:**
- ❌ UTF-8 with BOM
- ❌ CRLF (Windows)

## In VS Code einstellen

### Aktuellen Datei-Encoding prüfen/ändern:

1. Öffne die Datei (z.B. `cloud-sync.sh`)
2. Unten rechts in der Statusleiste:
   - Klicke auf "UTF-8 with BOM" oder "CRLF"
   - Wähle "Save with Encoding" → "UTF-8"
   - Wähle "LF" für Zeilenumbrüche

### Projekt-weite Einstellungen

Erstelle/bearbeite `.vscode/settings.json`:

```json
{
  "files.encoding": "utf8",
  "files.eol": "\n",
  "files.insertFinalNewline": true
}
```

## Dateien die dies betrifft

- `lib/cloud-sync.sh`
- `install-web.sh`
- `uninstall.sh`

Python-Dateien (.py) können UTF-8 with BOM verwenden, aber UTF-8 ohne BOM ist bevorzugt.

## Probleme vermeiden

### Vor jedem Upload zum Server:

1. Prüfe alle .sh Dateien auf korrektes Encoding
2. Teste das Script lokal (wenn möglich)
3. Nach dem Kopieren zum Server:
   ```bash
   # CRLF zu LF konvertieren (falls nötig)
   dos2unix /pfad/zur/datei.sh
   
   # Oder mit sed:
   sed -i 's/\r$//' /pfad/zur/datei.sh
   ```

## Symptome falscher Encodierung

### BOM in Bash-Scripts:
```
/bin/bash^M: bad interpreter: No such file or directory
```

### CRLF Zeilenumbrüche:
```
syntax error near unexpected token `$'\r''
```

## Lösung

```bash
# Alle .sh Dateien korrigieren:
find /usr/local/bin/cloud-sync -name "*.sh" -exec dos2unix {} \;

# Oder mit sed:
find /usr/local/bin/cloud-sync -name "*.sh" -exec sed -i 's/\r$//' {} \;
```
