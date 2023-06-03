#!/system/bin/sh

MODDIR="$(dirname "$(readlink -f "$0")")"

# 赋予执行权限
chmod 755 "$MODDIR"/bin/alist

# 等待系统启动成功
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 5s
done

# 防止系统挂起
echo "PowerManagerService.noSuspend" > /sys/power/wake_lock

# 启动 alist 服务
"$MODDIR"/bin/alist server --data "$MODDIR"/data &

# 启动 update.sh 服务
/system/bin/sh "$MODDIR"/update.sh &

# 启动 control.sh 服务
/system/bin/sh "$MODDIR"/control.sh &
