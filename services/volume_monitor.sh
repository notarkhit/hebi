#!/usr/bin/env bash

# Kill any orphaned instances from previous hot-reloads
for pid in $(pgrep -f "volume_monitor.sh"); do
    if [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
        kill -9 "$pid" 2>/dev/null
    fi
done

update_volume() {
    # Run pactl commands in parallel to cut execution time in half
    {
        VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{print $5}' | tr -d '%')
        echo "$VOL" > /tmp/hebi_volume
    } &
    {
        MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk 'NR==1{print $2}')
        echo "$MUTE" > /tmp/hebi_mute
    } &
    wait
}

update_volume

pactl subscribe | grep --line-buffered "Event 'change' on sink" | while read -r _; do
    update_volume
    
    # Flush the pipe: instantly discard any events that queued up while update_volume was running
    while read -t 0 -r _; do read -r _; done
done
