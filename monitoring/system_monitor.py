import psutil
import time

def check_cpu():
    print(f"CPU-Auslastung: {psutil.cpu_percent()}%")

while True:
    check_cpu()
    time.sleep(5)
