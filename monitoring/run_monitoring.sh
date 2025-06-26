#!/bin/bash

# ──────────────────────────────────────────────────────────────
# run_monitoring.sh
# Ruft per SSH das Powershell-Skript auf dem Windows-Server ab,
# loggt die Ausgabe mit Zeitstempel und zeigt zuletzt X Abrufe.
# ──────────────────────────────────────────────────────────────

# SSH-Zugangsdaten
USER="Server01"
SERVER="192.168.178.176"
PASSWORD="1234"

# Log-Datei
LOG_FILE="$HOME/server-monitoring-projekt/logs/server_monitoring.log"

# Anzahl der anzuzeigenden Abrufe (Standard: 10)
NUM_BLOCKS=${1:-3}

# Vorbedingung: sshpass installiert?
if ! command -v sshpass &> /dev/null; then
  echo -e "\e[31mFehler:\e[0m sshpass nicht gefunden. Installiere es mit:"
  echo "  sudo apt-get update && sudo apt-get install sshpass"
  exit 1
fi

# Log-Verzeichnis und Datei sicherstellen
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Abruf starten und in Logfile schreiben
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo -e "\n$TIMESTAMP - START neuer Abruf" >> "$LOG_FILE"

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no \
  "$USER@$SERVER" \
  'powershell -File C:\Users\Server01\Documents\get_systems_info.ps1' \
  >> "$LOG_FILE"

# Ausgabe: letzte NUM_BLOCKS vollständige Abrufe
start_lines=$(grep -n "START neuer Abruf" "$LOG_FILE" | cut -d: -f1)
total_starts=$(echo "$start_lines" | wc -l)

# Wenn angefragte Anzahl größer als vorhanden, anpassen
if [ "$NUM_BLOCKS" -gt "$total_starts" ]; then
  NUM_BLOCKS=$total_starts
fi

echo -e "\n\e[32mLetzte $NUM_BLOCKS von $total_starts vollständigen Abrufen:\e[0m"

starts_to_show=$(echo "$start_lines" | tail -n "$NUM_BLOCKS")

mapfile -t lines <<< "$starts_to_show"
total_lines=$(wc -l < "$LOG_FILE")

for ((i=0; i<${#lines[@]}; i++)); do
  start=${lines[$i]}
  if [ $((i+1)) -lt ${#lines[@]} ]; then
    end=$(( ${lines[$((i+1))]} - 1 ))
  else
    end=$total_lines
  fi

  echo -e "\033[36m========================================\033[0m"
  sed -n "${start},${end}p" "$LOG_FILE"
done

echo ""

