#!/system/bin/sh
MODDIR=${0%/*}

ui_print " -------------------------- "
ui_print " ------ 安装中，请稍等..."
sleep 1

ui_print " ------ 官方最新版本""`(curl -Ls "https://api.github.com/repos/alist-org/alist/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')`"

alistVersion="$(cat module.prop | grep "version=")"
ui_print " ------ 模块版本$(echo ${alistVersion##*=})"

ui_print " ------ 默认开机自启alist进程"

ui_print " ------ 开机后执行/data/adb/modules/Alist/目录内start.sh文件"

ui_print " ------ update.sh、control.sh文件提供自动更新、开关控制启动停止"

ui_print " ------ 更新间隔为2小时检查一次，可自行修改update.sh文件"

ui_print " ------ 网页后台地址:127.0.0.1:5244 账户 admin 密码 5244"

sleep 1
ui_print " ------ 安装已完成，请重启 ↘"
ui_print " -------------------------- "

