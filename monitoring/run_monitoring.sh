#!/bin/bash

# ──────────────────────────────────────────────────────────────
# run_monitoring.sh
# Ruft per SSH das Powershell-Skript auf dem Windows-Server ab,
# loggt die Ausgabe mit Zeitstempel und zeigt zuletzt X vollständige Abrufe.
# ──────────────────────────────────────────────────────────────

USER="Server01"
SERVER="192.168.178.176"
PASSWORD="1234"

LOG_FILE="$HOME/server-monitoring-projekt/logs/server_monitoring.log"
NUM_LINES=${1:-10}  # Anzahl Abrufe, Standard 10

# sshpass prüfen
if ! command -v sshpass &>/dev/null; then
  echo -e "\e[31mFehler:\e[0m sshpass nicht gefunden. Bitte installieren: sudo apt-get install sshpass"
  exit 1
fi

# Log-Verzeichnis + Datei sicherstellen
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Abruf starten und in Logfile schreiben
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo -e "\n$TIMESTAMP - START neuer Abruf" >> "$LOG_FILE"

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$SERVER" \
  'powershell -File C:\Users\Server01\Documents\get_systems_info.ps1' >> "$LOG_FILE"

# Anzahl aller Abrufe im Log zählen
total=$(grep -c '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} - START neuer Abruf' "$LOG_FILE")

# Anzahl zum Anzeigen bestimmen (max total)
num_show=$NUM_LINES
if (( total < NUM_LINES )); then
  num_show=$total
fi

echo -e "\n\e[32mLetzte $num_show von $total vollständigen Abrufen:\e[0m"

# Ausgabe der letzten num_show vollständigen Abrufe
# Wir lesen den Log rückwärts, splitten die Blöcke, und zeigen die letzten an

# grep alle Start-Zeilen mit Zeilennummer
mapfile -t start_lines < <(grep -n '^[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\} - START neuer Abruf' "$LOG_FILE" | cut -d: -f1)

if (( ${#start_lines[@]} == 0 )); then
  echo "Keine Abrufe gefunden."
  exit 0
fi

# Wir holen die letzten num_show Startzeilen
start_lines=("${start_lines[@]: -$num_show}")

# Für jede Startlinie den Block bis zur nächsten Startlinie oder Dateiende extrahieren
for ((i=0; i<${#start_lines[@]}; i++)); do
  start_line=${start_lines[i]}
  if (( i == ${#start_lines[@]} - 1 )); then
    # letzte Startlinie → bis Ende Datei
    sed -n "${start_line},\$p" "$LOG_FILE"
  else
    next_start_line=${start_lines[i+1]}
    sed -n "${start_line},$((next_start_line - 1))p" "$LOG_FILE"
  fi
  echo -e "========================================"
done
