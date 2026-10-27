#!/bin/bash

unbound -d -c /etc/unbound/unbound.conf.d/pi-hole.conf &
unbound_pid=$!

/usr/bin/start.sh &
pihole_pid=$!

shutdown() {
    kill -TERM "$unbound_pid" "$pihole_pid" 2>/dev/null || true
    wait "$unbound_pid" "$pihole_pid" 2>/dev/null || true
}

trap shutdown TERM INT
wait -n "$unbound_pid" "$pihole_pid"
exit_code=$?
shutdown
exit "$exit_code"
