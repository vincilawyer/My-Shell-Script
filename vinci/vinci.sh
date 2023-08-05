#!/bin/bash 
############################################################################################################################################################################################
##############################################################################   启动程序源代码   ########################################################################################
############################################################################################################################################################################################
#程序组成结构:1、启动程序（即本程序）,用于下载、启动更新update程序和主程序（该两程序及本程序容错率为0）。
#2、update程序，用于更新、加载配置文件。
#3、主程序，诠释程序作用。
echo 一
echo 启动码 $startcode，$1
echo 路径1：$0 
echo 路径2：$ZSH_NAME
echo 环境1：$$   
echo 环境2：$SHELL
sleep 5

############################################################################################################################################################################################
##############################################################################   shell调整环境   ########################################################################################
############################################################################################################################################################################################
#环境切换前的语句不会再次执行，且变量清空。因此shell环境切换需前置。切换后，if语句内的其他代码也不会被执行。
if uname -a | grep -q 'Darwin'; then
    [[ $(ps -p $$ -o comm=) == *"bash"* ]] && exec "/bin/zsh" "$0" "$startcode"
fi
echo 二
echo 启动码 $startcode，$1
echo 路径1：$0 
echo 路径2：$ZSH_NAME
echo 环境1：$$   
echo 环境2：$SHELL
sleep 5

####### 版本更新相关参数 ######
Version=2.00 
def_name="vinci"          
clear
#$startcode   为启动时传递的更新指令


############################################################################################################################################################################################
##############################################################################   不同系统配置及变量   ########################################################################################
############################################################################################################################################################################################
####### Debian系统启动程序网址、路径 ######
if uname -a | grep -q 'Debian'; then 
    CURSHELL="bash"
    echo "检测系统为Debian，当前Shell环境为$CURSHELL，正在配置中..."
    path_def="/usr/local/bin/$def_name"   
    
####### Android系统启动程序网址、路径 ######
elif uname -a | grep -q 'Android'; then 
    CURSHELL="bash"
    echo "检测系统为Android，当前Shell环境为$CURSHELL，正在配置中..."
    path_def="/data/data/com.termux/files/usr/bin/$def_name"                                           
                                                                
####### Mac系统启动程序网址、路径 ######
elif uname -a | grep -q 'Darwin'; then 
    CURSHELL="zsh"
    echo "检测系统为Mac，已切换Shell环境为$(ps -p $$ -o comm=)，正在配置中..."
    #允许注释与代码同行
    setopt interactivecomments
    #让数组编号与bash一致，从0开始
    setopt ksh_arrays
    #打开终端网络代理
    export http_proxy=http://127.0.0.1:1087;export https_proxy=http://127.0.0.1:1087;export ALL_PROXY=socks5://127.0.0.1:1086
    path_def="/usr/local/bin/$def_name"
    
###### 其他系统启动程序网址、路径 ######
else 
    CURSHELL="bash"
    echo "未知系统，当前Shell环境为$SHELL，正在配置默认版本中..."
    echo "未知系统"
    sleep 5
fi  

############################################################################################################################################################################################
##############################################################################   其他基本变量变量   ########################################################################################
############################################################################################################################################################################################
####### 定义本脚本名称、应用数据路径 ######
data_name="$HOME/myfile"                #应用数据文件夹位置路径 
data_path="$data_name/${def_name}_src"  #应用数据文件夹位置名                                               
mkdir "$data_name"  >/dev/null 2>&1     #创建文件夹                                                
mkdir "$data_path"  >/dev/null 2>&1     #应用资源文件夹                                                  

#### 配置文件、程序网址、路径 ####
#仓库
link_repositories="https://raw.githubusercontent.com/vincilawyer/Bash/main/"            
#update.src.sh
link_update="${link_repositories}library/update.src.sh"                                  
path_update="$data_path/update.src.sh"                                                
#main.src.sh
link_main="${link_repositories}vinci/main.src.sh"                                    
path_main="$data_path/main.src.sh"                                                    
#启动程序下载网址
link_def="${link_repositories}vinci/vinci.sh" 

############################################################################################################################################################################################
##############################################################################   脚本退出及报错   ########################################################################################
############################################################################################################################################################################################
######  退出函数 ######      
function quit() {
local exitnotice="$1"
local scrname="$2"
local funcname1="$3"
local funcname2="$4"
   if ((exitnotice == 1)); then
        clear
   elif [ -n "$exitnotice" ]; then
        echo -e "${RED}出现错误：$exitnotice。错误代码详见以下：${NC}"
        echo -e "${RED}错误函数为：${FUNCNAME[1]}${NC}"
        echo -e "${RED}调用函数为：${FUNCNAME[2]}${NC}"
        echo -e "${RED}错误模块为：${BASH_SOURCE[1]}${NC}"
   fi            
   echo -e "${GREED}已退出vinci脚本！${NC}"
   exit
}

#######   当脚本错误退出时，启动更新检查   ####### 
function handle_error() {
    echo "脚本运行出现错误！"
    echo -e "${RED}错误代码详见以下：${NC}"
    echo -e "${RED}错误函数为：$funcname1${NC}"
    echo -e "${RED}调用函数为：$funcname2${NC}"
    echo -e "${RED}错误模块为：$funcname2${NC}"
    quit
}

#######   当脚本退出   ####### 
function normal_exit() { 
:
}

#######   脚本退出前执行  #######   
trap 'handle_error' ERR
trap 'normal_exit' EXIT

############################################################################################################################################################################################
##############################################################################   基础更新   ########################################################################################
############################################################################################################################################################################################

function base_load {
      #检测代码是本地启动还是网络或其他异地启动,异地则为更新模式
      #[[ "$0" == "$path_def" ]] || startcode=1
      
      #更新模式
     if ((startcode==1)) || ! [ -e "$path_update" ]; then
         echo "正在启动基础更新..."
         if ! curl -H 'Cache-Control: no-cache' -L "$link_update" -o "$path_update" >/dev/null 2>&1 ; then echo "更新检查程序下载失败，请检查网络！"; wait; fi
     fi

     #载入更新检查文件，并获取错误输出
     wrongtext="$(source "$path_update" 2>&1 >/dev/null)"
     if [ -n "$wrongtext" ]; then 
          echo "当前更新检查程序缺失或存在语法错误，未能启动主程序，报错内容为：" 
          echo "$wrongtext"
          quit
     else
          source "$path_update"
     fi    

     #更新本程序
     update_load "$path_def" "$link_def" "$def_name脚本" 2 "$startcode"
    
     #更新主程序   
     update_load "$path_main" "$link_main" "主程序" 1 "$startcode"

}
############################################################################################################################################################################################
##############################################################################   开始运行   ########################################################################################
############################################################################################################################################################################################
base_load
main
