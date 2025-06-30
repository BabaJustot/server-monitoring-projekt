#!/bin/bash

# Logfile
logfile="./logs/server_monitoring.log"

# Schwellenwerte
cpu_warn=80
ram_warn=7000

# Abrufnummer berechnen
last_number=$(grep -E "^[0-9]+ - " "$logfile" | tail -n 1 | awk '{print $1}')
if [ -z "$last_number" ]; then
    number=1
else
    number=$((last_number + 1))
fi

# Funktionen
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk -F',' '{ for(i=1;i<=NF;i++) if($i ~ /id/) print 100 - $i }' | awk '{printf "%.1f", $1}'
}

get_ram_used() {
    free -m | awk '/Mem:/ {print $3}'
}

get_ram_total() {
    free -m | awk '/Mem:/ {print $2}'
}

get_process_count() {
    ps aux | wc -l
}

get_disk_used_gb() {
    local used=$(df / | awk 'NR==2 {print $3}')
    echo $(( (used + 1023) / 1024 ))
}

get_disk_total_gb() {
    local total=$(df / | awk 'NR==2 {print $2}')
    echo $(( (total + 1023) / 1024 ))
}

get_logged_in_users() {
    who | wc -l
}

# Messwerte erfassen
cpu=$(get_cpu_usage)
ram_used=$(get_ram_used)
ram_total=$(get_ram_total)
processes=$(get_process_count)
disk_used=$(get_disk_used_gb)
disk_total=$(get_disk_total_gb)
users_logged_in=$(get_logged_in_users)

# Logdatei schreiben
echo "$number - $(date '+%Y-%m-%d %H:%M:%S')" >> "$logfile"
echo "CPU: ${cpu}%" >> "$logfile"
echo "CPU_Warn: ${cpu_warn}%" >> "$logfile"
echo "RAM_Used: ${ram_used}MB" >> "$logfile"
echo "RAM_Warn: ${ram_warn}MB" >> "$logfile"
echo "RAM_Total: ${ram_total}MB" >> "$logfile"
echo "Processes: $processes" >> "$logfile"
echo "Disk_Used: ${disk_used}GB" >> "$logfile"
echo "Disk_Total: ${disk_total}GB" >> "$logfile"
echo "Users_Logged_In: $users_logged_in" >> "$logfile"

# Schwellenwert-Überprüfung
if (( $(echo "$cpu > $cpu_warn" | awk '{print ($1>$2)?1:0}' cpu="$cpu" cpu_warn="$cpu_warn") )); then
    echo "WARNUNG: CPU-Auslastung über ${cpu_warn}%!" | tee -a "$logfile"
fi

if [ "$ram_used" -gt "$ram_warn" ]; then
    echo "WARNUNG: RAM-Auslastung über ${ram_warn}MB!" | tee -a "$logfile"
fi

echo "" >> "$logfile"

# Letzte 5 Abrufe anzeigen
echo ""
echo "Letzte 5 Abrufe:"
echo "========================================"
grep -E "^[0-9]+ - " "$logfile" | tail -n 5 | while read -r line; do
    abruf_nummer=$(echo "$line" | awk '{print $1}')
    echo "$line"
    sed -n "/^$abruf_nummer - /,/^$/p" "$logfile" | sed '1d'
    echo "========================================"
done
