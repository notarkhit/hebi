#!/bin/sh
# Outputs one labelled line per metric, then exits.
# Called every N seconds by SystemInfoService.qml.

# CPU: read two snapshots 500ms apart for an accurate idle delta
read_cpu() {
    awk '/^cpu /{idle=$5; tot=0; for(i=2;i<=NF;i++) tot+=$i; print idle, tot; exit}' /proc/stat
}
set -- $(read_cpu); idle1=$1; tot1=$2
sleep 0.5
set -- $(read_cpu); idle2=$1; tot2=$2
didle=$((idle2 - idle1)); dtot=$((tot2 - tot1))
if [ "$dtot" -gt 0 ]; then
    awk -v d="$didle" -v t="$dtot" 'BEGIN{printf "cpu:%.1f\n", (1 - d/t)*100}'
else
    echo "cpu:0"
fi

# RAM
awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "mem:%d:%d\n",t-a,t}' /proc/meminfo

# Swap
awk '/SwapTotal/{t=$2}/SwapFree/{f=$2}END{if(t>0)printf "swap:%d:%d\n",t-f,t;else print "swap:0:1"}' /proc/meminfo

# Temperature — highest thermal_zone, convert millidegrees
t=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -n | tail -1)
if [ -n "$t" ]; then
    [ "$t" -gt 1000 ] && t=$((t / 1000))
    echo "temp:$t"
fi

# Disk root %
df / | awk 'NR==2{gsub(/%/,"",$5); print "disk:"$5}'

# Network speed — use /proc/net/dev, skip loopback
awk 'NR>2 && !/^ *lo:/{rx+=$2; tx+=$10} END{printf "net:%d:%d\n", rx, tx}' /proc/net/dev
