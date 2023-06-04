#!/system/bin/sh

# 获取当前脚本所在目录
MODDIR="$(dirname "$(readlink -f "$0")")"

# busybox的路径地址
busybox="/data/adb/magisk/busybox"

# 更新的源
URL="https://packages-cf.termux.dev/apt/termux-main/pool/main/a/alist/" 

# 下载解压后需要提取的路径文件
File_path="./data/data/com.termux/files/usr/bin/alist"

while true; do
    # 判断网络是否连通
    if ping -q -c 1 -W 1 www.baidu.com >/dev/null; then
    
        # 比较版本号
        version_ge() {
            test "$(echo -e "$1\n$2" | sort -V | tail -n 1)" = "$2"
        }

        # 更新列表
        url_version="$(${busybox} wget -q --no-check-certificate -O - "${URL}" | grep -o 'alist_[^"]*' | sed 's/alist_//' | grep '_aarch64.deb$' | sed 's/_aarch64\.deb//' | tail -n 1)"
        
        version="`$MODDIR/bin/alist version | egrep '^Version:' | awk '{print $2}'`"
                
        if version_ge "${url_version}" "${version}"; then
            echo "web更新$(date "+%Y-%m-%d %H:%M:%S") v${version}已是最新版本" >> "$MODDIR/log.log"
            
            # 修改模块信息文件中的版本号，并重新导入变量配置文件
            sed -i "s/^version=.*/version=v${version}/g" "${MODDIR}/module.prop"
            
        else
            echo "web更新$(date "+%Y-%m-%d %H:%M:%S") v${version}版本较低，正在更新 ..." >> "$MODDIR/log.log"
            
            # 刷新下载的文件名
            Alist_file="alist_$(${busybox} wget -q --no-check-certificate -O - "${URL}" | grep -o 'alist_[^"]*' | sed 's/alist_//' | grep '_aarch64.deb$' | sed 's/_aarch64\.deb//' | tail -n 1)""_aarch64.deb" 

            # 下载并解压更新包
            ${busybox} wget -O "${MODDIR}/${Alist_file}" "${URL}${Alist_file}" 
            chmod 755 "${MODDIR}/${Alist_file}"
            ${busybox} ar -p "${MODDIR}/${Alist_file}" data.tar.xz > "${MODDIR}/data.tar.xz" && ${busybox} tar -xf "${MODDIR}/data.tar.xz"

            # 将alist二进制文件和相关资源复制到对应目录下
            cp -f "$(echo "${File_path}")" "$MODDIR/bin"   
            chmod 755 "$MODDIR/bin/alist"
                    
            # 清理临时目录
            rm "$MODDIR/${Alist_file}"
            rm "$MODDIR/data.tar.xz"
            rm "$MODDIR/data/data"
            
            # 更新列表
            version="`$MODDIR/bin/alist version | egrep '^Version:' | awk '{print $2}'`"
            
            # 修改模块信息文件中的版本号，并重新导入变量配置文件
            sed -i "s/^version=.*/version=v${version}/g" "${MODDIR}/module.prop"
            
            echo "web更新$(date "+%Y-%m-%d %H:%M:%S") 准备重启进程 ..." >> "$MODDIR/log.log"
            # 重启进程
            PIDS=`ps -ef | grep alist | grep -v grep | awk '{print $2}'` 
            if [ "$PIDS" != "" ]; then
	            kill -9 $PIDS
	            $MODDIR/bin/alist server --data $MODDIR/data &
            else
	            $MODDIR/bin/alist server --data $MODDIR/data &
            fi
        fi
    else
        echo "web更新$(date "+%Y-%m-%d %H:%M:%S") 网络未连接" >> "$MODDIR/log.log"
    fi
    sleep 1h
done
