#!/bin/bash

# Logfile
logfile="./logs/server_monitoring.log"

# Abrufnummer berechnen
last_number=$(grep -E "^[0-9]+ - " "$logfile" | tail -n 1 | awk '{print $1}')
if [ -z "$last_number" ]; then
    number=1
else
    number=$((last_number + 1))
fi

# Systemdaten auslesen
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d ',')
[ -z "$cpu" ] && cpu="-"

ram_used=$(free -m | awk '/Mem:/ {print $3}')
[ -z "$ram_used" ] && ram_used="-"

ram_total=$(free -m | awk '/Mem:/ {print $2}')
[ -z "$ram_total" ] && ram_total="-"

processes=$(ps aux | wc -l)
[ -z "$processes" ] && processes="-"

disk_used=$(df -h / | awk 'NR==2 {print $3}' | tr -d 'G')
[ -z "$disk_used" ] && disk_used="-"

disk_total=$(df -h / | awk 'NR==2 {print $2}' | tr -d 'G')
[ -z "$disk_total" ] && disk_total="-"

# In Logdatei schreiben
echo "$number - $(date '+%Y-%m-%d %H:%M:%S')" >> "$logfile"
echo "CPU:$cpu" >> "$logfile"
echo "RAM_Used:$ram_used" >> "$logfile"
echo "RAM_Total:$ram_total" >> "$logfile"
echo "Processes:$processes" >> "$logfile"
echo "Disk_Used:$disk_used" >> "$logfile"
echo "Disk_Total:$disk_total" >> "$logfile"
echo "" >> "$logfile"

# Die letzten 5 anzeigen
echo ""
echo "Letzte 5 Abrufe:"
echo "========================================"
grep -E "^[0-9]+ - " "$logfile" | tail -n 5 | while read -r line; do
    abruf_nummer=$(echo "$line" | awk '{print $1}')
    echo "$line"
    sed -n "/^$abruf_nummer - /,/^$/p" "$logfile" | sed '1d'
    echo "========================================"
done
