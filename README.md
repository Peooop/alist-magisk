# Alist-magisk
本模块的alist二进制文件来自termux的镜像源 <br>
模块默认开机自启alist进程 <br>
模块内提供的update.sh实现了自动对比源内版本号低于最新版时自动更新，使用的前提你需要启动这个脚本保留一个进程，检查循环为1小时一次 <br>
模块内control.sh用于检查magisk的启动开关，使用也需要开启一个进程 <br>
