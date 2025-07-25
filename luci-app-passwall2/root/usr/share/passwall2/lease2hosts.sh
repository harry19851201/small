#!/bin/sh

# dhcp.leases to hosts

CONFIG=passwall2
TMP_PATH=/tmp/etc/${CONFIG}
TMP_PATH2=/tmp/etc/${CONFIG}_tmp
LOCK_FILE=/tmp/lock/${CONFIG}_lease2hosts.lock
LEASE_FILE="/tmp/dhcp.leases"
HOSTS_FILE="$TMP_PATH2/dhcp-hosts"
TMP_FILE="/tmp/dhcp-hosts.tmp"

exec 99>"$LOCK_FILE"
flock -n 99
if [ "$?" != 0 ]; then
	exit 0
fi

reload_dnsmasq_pids() {
	local pidfile pid
	find $TMP_PATH/acl -type f -name 'dnsmasq.pid' 2>/dev/null | while read pidfile; do
		if [ -s "$pidfile" ]; then
			read pid < "$pidfile"
			if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
				kill -HUP "$pid"
			fi
		fi
	done
}

while true; do

	if [ -f "$LEASE_FILE" ]; then
		awk 'NF >= 4 && $4 != "*" {print $3" "$4}' "$LEASE_FILE" | sort > "$TMP_FILE"
		if [ -s "$TMP_FILE" ]; then
			if [ ! -f "$HOSTS_FILE" ] || ! cmp -s "$TMP_FILE" "$HOSTS_FILE"; then
				mv "$TMP_FILE" "$HOSTS_FILE"
				reload_dnsmasq_pids
			else
				rm -f "$TMP_FILE"
			fi
		else
			if [ -s "$HOSTS_FILE" ]; then
				: > "$HOSTS_FILE"
				reload_dnsmasq_pids
			fi
			rm -f "$TMP_FILE"
		fi
	fi

	sleep 60

done 2>/dev/null
