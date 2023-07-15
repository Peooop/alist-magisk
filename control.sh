#!/system/bin/sh

MODDIR="$(dirname "$(readlink -f "$0")")"

while true; do
    if [ -f "/data/adb/modules/Alist/disable" ]; then
        pkill -f 'alist'
    else
        pgrep -f 'alist' >/dev/null || $MODDIR/bin/alist server --data "$MODDIR/data" &
    fi
    sleep 5
done
