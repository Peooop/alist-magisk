#!/system/bin/sh

# 获取当前脚本所在目录
MODDIR="$(dirname "$(readlink -f "$0")")"

# busybox的路径地址
busybox="/data/adb/magisk/busybox"

# 更新的源
URL="https://packages-cf.termux.dev/apt/termux-main/pool/main/a/alist/"

# 下载解压后需要提取的路径文件
File_path="${MODDIR}/data/data/com.termux/files/usr/bin/alist"

# 检查网络连通性函数
check_connectivity() {
    if ! ping -q -c 1 -W 1 www.baidu.com >/dev/null; then
        sleep 40s
        return 1
    fi
    return 0
}

# 比较版本号函数
version_ge() {
    test "$(echo -e "$1\n$2" | sort -V | tail -n 1)" = "$2"
}

while true; do
    # 获取log.log文件大小
    log_size=$(wc -c < "${MODDIR}/log.log")

    # 检查是否超过1MB
    if [ "$log_size" -gt 1048576 ]; then
        # 删除log.log文件
        rm "${MODDIR}/log.log"
    fi

    # 判断网络是否连通
    if ! check_connectivity; then
        continue
    fi
    # 获取最新版本号
    url_version="$(${busybox} wget -q --no-check-certificate -O - "${URL}" | grep -o 'alist_[^"]*' | sed 's/alist_//' | grep '_aarch64.deb$' | sed 's/_aarch64\.deb//' | tail -n 1)"
    # 获取当前Alist版本号
    version="$("${MODDIR}/bin/alist" version | awk '/^Version:/ {print $2}')"

    if version_ge "${url_version}" "${version}"; then
        echo "web更新$(date "+%Y-%m-%d %H:%M:%S") v${version}已是最新版本" >> "${MODDIR}/log.log"

        # 修改模块信息文件中的版本号，并重新导入变量配置文件
        sed -i "s/^version=.*/version=v${version}/g" "${MODDIR}/module.prop"

    else
        echo "web更新$(date "+%Y-%m-%d %H:%M:%S") v${version}版本较低，正在更新 ..." >> "${MODDIR}/log.log"

        # 下载并解压更新包
        Alist_file="alist_${url_version}_aarch64.deb"
        ${busybox} wget -O "${MODDIR}/${Alist_file}" "${URL}${Alist_file}"
        chmod 755 "${MODDIR}/${Alist_file}"
        ${busybox} ar -p "${MODDIR}/${Alist_file}" data.tar.xz > "${MODDIR}/data.tar.xz" && ${busybox} tar -xf "${MODDIR}/data.tar.xz"

        # 复制文件到对应目录下
        mv -f "${File_path}" "${MODDIR}/bin/alist"
        chmod 755 "${MODDIR}/bin/alist"

        # 清理临时文件
        find "${MODDIR}" -name "alist_*_aarch64.deb" -delete
        rm "${MODDIR}/data.tar.xz"
        rm -r "${MODDIR}/data/data"

        # 更新列表
        version="$("${MODDIR}/bin/alist" version | awk '/^Version:/ {print $2}')"

        # 修改模块信息文件中的版本号，并重新导入变量配置文件
        sed -i "s/^version=.*/version=v${version}/g" "${MODDIR}/module.prop"

        echo "web更新$(date "+%Y-%m-%d %H:%M:%S") 准备重启进程 ..." >> "${MODDIR}/log.log"
        # 重启进程
        PIDS=$(ps -ef | grep "[a]list server" | awk '{print $2}')
        if [ -n "$PIDS" ]; then
            kill -9 $PIDS
        fi
        "${MODDIR}/bin/alist" server --data "${MODDIR}/data" &
    fi

    sleep 4h
done