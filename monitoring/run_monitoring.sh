#!/bin/bash

# SSH-Zugangsdaten
USER=Server01
SERVER=192.168.178.176

# Powershell-Skript auf dem Windows-Server ausführen und Ausgabe abholen
sshpass -p '1234' ssh $USER@$SERVER 'powershell -File C:\Users\Server01\Documents\get_systems_info.ps1' >> ~/server-monitoring-projekt/logs/server_monitoring.log

