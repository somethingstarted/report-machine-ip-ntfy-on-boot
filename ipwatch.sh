#!/bin/bash
# Requirements: curl

NTFY_TOPIC="mytopic"    # replace with your ntfy topic
INTERFACES=("eno1" "wg0")
CHECK_INTERVAL=30       # seconds
MAX_TRIES=$((20 * 60 / CHECK_INTERVAL))  # 20 minutes worth of checks
HOSTNAME=$(hostname)

declare -A found_ips

for iface in "${INTERFACES[@]}"; do
    found_ips[$iface]=""
done

for ((i=1; i<=MAX_TRIES; i++)); do
    all_found=true

    for iface in "${INTERFACES[@]}"; do
        if [[ -z "${found_ips[$iface]}" ]]; then
            ip=$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
            if [[ -n "$ip" ]]; then
                found_ips[$iface]="$ip"
            else
                all_found=false
            fi
        fi
    done

    if $all_found; then
        break  # stop early if we got both IPs
    fi

    sleep "$CHECK_INTERVAL"
done

# Build message
msg="[$HOSTNAME] IP check results:"
for iface in "${INTERFACES[@]}"; do
    if [[ -n "${found_ips[$iface]}" ]]; then
        msg+=" $iface=${found_ips[$iface]};"
    else
        msg+=" $iface=NOT_FOUND;"
    fi
done

curl -d "$msg" ntfy.sh/"$NTFY_TOPIC"
