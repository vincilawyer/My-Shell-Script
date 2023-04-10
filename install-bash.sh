#!/bin/bash
if [[ -z $current_Version ]]; then
    echo "正在下载Vultr-Debian11脚本"
    wget --no-cache https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh -O /usr/local/bin/vinci
    chmod +x /usr/local/bin/vinci
    vinci
else
    if [ "$current_Version" == "force" ]; then
       wget --no-cache https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh -O /usr/local/bin/vinci
       chmod +x /usr/local/bin/vinci
       echo "强制更新已完成！"
       sleep 4
    else
        Version=$(curl -s https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh | grep 'Version=' | cut -d'=' -f2 | head -1)
        if [[ "${current_Version}" == "${Version}" ]]; then
           echo "当前已是最新版本(V$Version)，无需更新！"
           sleep 2
        else
           echo "当前版本号为：V${current_Version}"
           wget --no-cache https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh -O /usr/local/bin/vinci
           chmod +x /usr/local/bin/vinci
           echo "已更新至V$Version版本，即将进入管理系统！"
           sleep 4
        fi
    fi
fi
    
