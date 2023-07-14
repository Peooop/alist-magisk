#!/system/bin/sh

MODDIR="$(dirname "$(readlink -f "$0")")"

while true; do
    if ls /data/adb/modules/Alist/ | grep -q "disable"; then
        pkill -f 'alist'
    else
        pgrep -f 'alist' >/dev/null || $MODDIR/bin/alist server --data "$MODDIR/data" &
    fi
    sleep 3
done