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

# CPU-Auslastung in Prozent (100 - idle)
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' '{ print $1 }' | awk '{print $NF}')
if [ -n "$cpu_idle" ]; then
    cpu=$(echo "scale=1; 100 - $cpu_idle" | bc)
else
    cpu="-"
fi

# RAM in MB
ram_used=$(free -m | awk '/Mem:/ {print $3}')
[ -z "$ram_used" ] && ram_used="-"

ram_total=$(free -m | awk '/Mem:/ {print $2}')
[ -z "$ram_total" ] && ram_total="-"

# Prozesse
processes=$(ps aux | wc -l)
[ -z "$processes" ] && processes="-"

# Disk in GB, auf ganze Zahl runden
disk_used_bytes=$(df / | awk 'NR==2 {print $3}')   # in KB
disk_total_bytes=$(df / | awk 'NR==2 {print $2}')  # in KB

if [ -n "$disk_used_bytes" ] && [ -n "$disk_total_bytes" ]; then
    disk_used=$(( (disk_used_bytes + 1023*1024) / (1024*1024) ))  # Umrechnung KB -> GB, aufrunden
    disk_total=$(( (disk_total_bytes + 1023*1024) / (1024*1024) ))
else
    disk_used="-"
    disk_total="-"
fi

# Ausgabe in Logdatei mit Einheiten
echo "$number - $(date '+%Y-%m-%d %H:%M:%S')" >> "$logfile"
echo "CPU: ${cpu}%" >> "$logfile"
echo "RAM_Used: ${ram_used}MB" >> "$logfile"
echo "RAM_Total: ${ram_total}MB" >> "$logfile"
echo "Processes: $processes" >> "$logfile"
echo "Disk_Used: ${disk_used}GB" >> "$logfile"
echo "Disk_Total: ${disk_total}GB" >> "$logfile"
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
