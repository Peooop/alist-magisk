#!/system/bin/sh

# 获取当前脚本所在目录
MODDIR="$(dirname "$(readlink -f "$0")")"

# busybox的路径地址
BUSYBOX_PATH="/data/adb/magisk/busybox:/data/adb/ksu/bin/busybox"
BUSYBOX=""

# 更新的源
URL="https://packages-cf.termux.dev/apt/termux-main/pool/main/a/alist/"

# 架构
ARCH=$(uname -m)

# 检查网络连通性函数
check_connectivity() {
    if ! ping -q -c 1 -W 1 www.baidu.com >/dev/null; then
        sleep 5s
        return 1
    fi
    return 0
}

# 找到可用的busybox路径
find_busybox() {
    for path in $(echo $BUSYBOX_PATH | tr ":" "\n"); do
        if [ -f "$path" ]; then
            BUSYBOX="$path"
            break
        fi
    done
}

# 删除大于1MB的log.log文件
delete_log() {
    log_size=$(wc -c < "${MODDIR}/log.log")
    if [ "$log_size" -gt 1048576 ]; then
        rm "${MODDIR}/log.log"
    fi
}

# 下载并解压更新包
download_and_extract() {
    Alist_file="alist_${url_version}_${ARCH}.deb"
    mkdir -p "${MODDIR}/tmp"
    "${BUSYBOX}" wget -O "${MODDIR}/tmp/${Alist_file}" "${URL}${Alist_file}"
    chmod 755 "${MODDIR}/tmp/${Alist_file}"
    "${BUSYBOX}" ar -p "${MODDIR}/tmp/${Alist_file}" data.tar.xz > "${MODDIR}/tmp/data.tar.xz" && "${BUSYBOX}" tar -xf "${MODDIR}/tmp/data.tar.xz" -C "${MODDIR}/tmp"
}

# 复制更新后的文件到对应目录下
copy_files() {
    mv -f "${MODDIR}/tmp/data/data/com.termux/files/usr/bin/alist" "${MODDIR}/bin/alist"
    chmod 755 "${MODDIR}/bin/alist"
}

# 清理临时文件
cleanup() {
    rm -r "${MODDIR}/tmp"
}

# 比较版本号函数
version_ge() {
    test "$(echo -e "$1\n$2" | sort -V | tail -n 1)" = "$2"
}

# 更新列表并重启进程
update_and_restart() {
    echo "[$(date "+%Y-%m-%d] [%H:%M:%S")] 更新后v${version}版本" >> "${MODDIR}/log.log"
    sed -i "s/^version=.*/version=v${version}/g" "${MODDIR}/module.prop"
    if pgrep -f 'alist' >/dev/null; then
        pkill alist 
    fi
    "${MODDIR}/bin/alist" server --data "${MODDIR}/data" &
}

# 处理更新失败
handle_failed_update() {
    echo "[$(date "+%Y-%m-%d] [%H:%M:%S")] 更新失败" >> "${MODDIR}/log.log"
}

# 查找并设置busybox路径
find_busybox

while true; do
    delete_log
    if ! check_connectivity; then
        sleep 5s
        continue
    fi
    
    # 获取最新版本号
    url_version="$("${BUSYBOX}" wget -q --no-check-certificate -O - "${URL}" | grep -o 'alist_[^"]*' | sed 's/alist_//' | grep '_'"${ARCH}"'.deb$' | sed 's/_'"${ARCH}"'\.deb//' | tail -n 1)"
    
    # 获取当前Alist版本号
    version="$("${MODDIR}/bin/alist" version | awk '/^Version:/ {print $2}')"
    
    if [ -n "$url_version" ]; then
        if version_ge "${url_version}" "${version}"; then
            echo "[$(date "+%Y-%m-%d] [%H:%M:%S")] v${version}已是最新版本" >> "${MODDIR}/log.log"
            sed -i "s/^version=.*/version=v${version}/g" "${MODDIR}/module.prop"
        else
            echo "[$(date "+%Y-%m-%d] [%H:%M:%S")] v${version}版本较低，正在更新 ..." >> "${MODDIR}/log.log"
            download_and_extract
            copy_files
            cleanup

            max_retries=3
            retry_count=0

            while true; do
                version=$("${MODDIR}/bin/alist" version | awk '/^Version:/ {print $2}')
                if version_ge "${url_version}" "${version}"; then
                    update_and_restart
                    break
                fi

                sleep 5s
                ((retry_count++))

                if [[ ${retry_count} -eq ${max_retries} ]]; then
                    handle_failed_update
                    break
                fi
            done
        fi
    else
        echo "[$(date "+%Y-%m-%d] [%H:%M:%S")] 更新失败未获取到版本号" >> "${MODDIR}/log.log"
    fi
    
    sleep 4h
done