#!/usr/bin/env bash

update_volume() {
    VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{print $5}' | tr -d '%')
    MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk 'NR==1{print $2}')
    echo "$VOL" > /tmp/hebi_volume
    echo "$MUTE" > /tmp/hebi_mute
}

update_volume

LAST_UPDATE=0
pactl subscribe | grep --line-buffered "Event 'change' on sink" | while read -r _; do
    NOW=$(date +%s%N)
    # Debounce: max 20 updates per second (50 million nanoseconds)
    if (( NOW - LAST_UPDATE > 50000000 )); then
        update_volume
        LAST_UPDATE=$NOW
    fi
done
