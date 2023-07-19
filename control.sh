#!/system/bin/sh

MODDIR="$(dirname "$(readlink -f "$0")")"

get_local_ip() {
    # 获取本机局域网IP
    ip=$(ifconfig wlan0 | grep "inet addr" | awk '{print $2}' | awk -F ':' '{print $2}')

    # 打印IP地址
    echo "本机局域网IP地址:$ip"
}

while true; do

    if [ -f "/data/adb/modules/Alist/disable" ]; then
        pkill -f 'alist'       
    else
        pgrep -f 'alist' >/dev/null || $MODDIR/bin/alist server --data "$MODDIR/data" &
    fi
    result=$(pgrep -f 'update.sh')
    if [ -n "$result" ]; then
        status="更新[开启中]"
    else
        status="更新[已停止]"
    fi
    replacement="$status $(get_local_ip)"
    
    sed -i "s/\(description=\).*/\1$replacement/g" "$MODDIR/module.prop"
    
    sleep 3
done


