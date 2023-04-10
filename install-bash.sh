#!/bin/bash

function download {
    wget --no-cache https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh -O /usr/local/bin/vinci
    chmod +x /usr/local/bin/vinci
    Version=$(cat /usr/local/bin/vinci | grep 'Version=' | head -1 | cut -d'=' -f2)
    if [[ -z $Version ]]; then
      echo "下载失败，请检查网络！"
      sleep 3
      exit 0
    else
      echo "$1$Version$2"
      execute $Version
    fi
}

function execute {
    sleep 3
    vinci
    #如新版本存在错误
    if  [ ! $? == 0 ]; then
       #询问是否重新更新
       read -n 1 -p "新版本存在错误，是否重新更新？(y/n):" input
       if [ $input=="y" ]; then
           while true; do
              echo "新版本存在错误，正在尝试重新更新！...输入任意键退出"
              #每隔59秒更新一次
              read -t 59 -n 1 input
              # 如果用户输入不为空，则退出更新
              if [ ! -z $input ]; then
                  break
              fi  
              #强制更新
              wget --no-cache https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh -O /usr/local/bin/vinci
              chmod +x /usr/local/bin/vinci
              echo "重新更新完成，当前版本为V$1，正在尝试再次启动！"
              sleep 3
              vinci
              #如新版本没有错误，则执行新版本
              if  [ $? == 0 ]; then
                 break
              fi
           done
        else
          echo "已放弃重新更新！"
        fi
     fi
     exit 1
}

function main {
clear

#下载脚本请求
if [[ -z $current_Version ]]; then
    echo "正在下载Vultr-Debian11脚本..."
    download "Linux管理系统V" "已下载完成，即将进入系统！"   
    
#更新脚本请求
else
    #强制更新
    if [ "$current_Version" == "force" ]; then
       echo "正在强制更新Vultr-Debian11脚本..."
       download "Linux管理系统V" "已强制更新完成，即将重启管理系统！"

    #自动检查更新 
    else
        #检查最新版本号
        echo "正在检查版本更新..."
        Version=$(curl -s https://raw.githubusercontent.com/vincilawyer/Bash/main/Vultr-Debian11/Vultr-Debian11.sh | grep 'Version=' | cut -d'=' -f2 | head -1)
       
        #无需更新
        if [[ "${current_Version}" == "${Version}" ]]; then
           echo "当前已是最新版本(V$Version)，无需更新！"
           sleep 1.5
           exit 0
           
        #更新至最新版本
        else
           echo "当前版本号为：V${current_Version}，最新版本号为：V${Version}，即将更新！"
           download "已更新至V" "版本，即将重启管理系统！"
        fi
    fi
fi
  }

main
