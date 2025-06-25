#!/bin/bash

# ──────────────────────────────────────────────────────────────
# run_monitoring.sh
# Ruft per SSH das Powershell-Skript auf dem Windows-Server ab,
# loggt die Ausgabe mit Zeitstempel und zeigt zuletzt X Einträge.
# ──────────────────────────────────────────────────────────────

# SSH-Zugangsdaten
USER="Server01"
SERVER="192.168.178.176"
PASSWORD="1234"

# Log-Datei
LOG_FILE="$HOME/server-monitoring-projekt/logs/server_monitoring.log"

# Anzahl der anzuzeigenden Log-Zeilen (Standard: 10)
NUM_LINES=${1:-10}

# ──────────────────────────────────────────────────────────────
# 1) Vorbedingung: sshpass installieren?
# ──────────────────────────────────────────────────────────────
if ! command -v sshpass &> /dev/null; then
  echo -e "\e[31mFehler:\e[0m sshpass nicht gefunden. Installiere es mit:"
  echo "  sudo apt-get update && sudo apt-get install sshpass"
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# 2) Log-Verzeichnis und Datei sicherstellen
# ──────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# ──────────────────────────────────────────────────────────────
# 3) Abruf starten und in Logfile schreiben
# ──────────────────────────────────────────────────────────────
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo -e "\n$TIMESTAMP - START neuer Abruf" >> "$LOG_FILE"

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no \
  "$USER@$SERVER" \
  'powershell -File C:\Users\Server01\Documents\get_systems_info.ps1' \
  >> "$LOG_FILE"

# ──────────────────────────────────────────────────────────────
# 4) Ausgabe in der Konsole: letzten NUM_LINES Zeilen mit Block-Trennung
# ──────────────────────────────────────────────────────────────
echo -e "\n\e[32mLetzte $NUM_LINES Log-Einträge (nach Abruf gruppiert):\e[0m"

tail -n "$NUM_LINES" "$LOG_FILE" | awk '
  # findet Zeitstempel-Zeile
  /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} - START neuer Abruf$/ {
    print "\033[36m========================================\033[0m"
    print "\033[36m" $0 "\033[0m"
    next
  }
  # alle anderen Zeilen einrücken
  {
    print "  " $0
  }
'

echo ""
