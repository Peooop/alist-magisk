#!/system/bin/sh

MODDIR="$(dirname "$(readlink -f "$0")")"

while true; do # 循环
    if [ -f "./disable" ]; then
        if pgrep -f 'alist' >/dev/null; then
            echo "开关控制$(date "+%Y-%m-%d %H:%M:%S") 进程已存在，正在关闭 ..."
            pkill alist # 关闭进程
        fi
    else
        if pgrep -f 'alist' >/dev/null; then
            echo "开关控制$(date "+%Y-%m-%d %H:%M:%S") 进程已存在"
        else
            echo "开关控制$(date "+%Y-%m-%d %H:%M:%S") 进程不存在，启动 ..."
            $MODDIR/bin/alist server --data "$MODDIR/data" &
        fi
    fi
    sleep 3s # 暂停3秒后再次执行循环
done