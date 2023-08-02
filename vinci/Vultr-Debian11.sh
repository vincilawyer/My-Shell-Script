#!/bin/bash 
############################################################################################################################################################################################
##############################################################################   vinci脚本源代码   ########################################################################################
############################################################################################################################################################################################
###          目  录        
###   1.参数               
###   2.脚本启动及退出检查模块        
###   3.主函数
###   4.开发工具 
###   5.文本管理模块    
###   6.用户数据及应用配置管理模块       
###   7.系统工具
###   8.Docker
###   9.Nginx
###   10.Xui
###   11.Cloudflare
###   12.Tor
###   13.Frp
###   14.Chatgpt
############################################################################################################################################################################################
############################################################################################################################################################################################
###   说明:
###   一、输入参数：1.则为用户报错更新。2.则本脚本为更新检查程序唤醒。
###   二、输出返回值：1.则为程序报错,要求返回更新检查程序继续更新;2.当脚本出现语法错误，可能返回值为2;3.程序暂无错，用户自主要求返回程序更新。


####### 版本更新相关参数 ######
Version=3.29  #版本号 
script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"      #获取当前脚本的目录路径
script_name="$(basename "${BASH_SOURCE[0]}")"                                     #获取当前脚本的名称
file_path="$script_path/$script_name"                                             #获取当前脚本的文件路径
Version1="$Version.$(n="$(cat "$file_path")" &&  echo "${#n}")"                   #脚本完整版本号
startnum="$1"                                                                     #当前脚本的启动指令：1、告知本程序由更新程序唤醒；


####### 定义颜色 ######
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BLACK="\033[40m"
NC='\033[0m'

####### 定义全局变量  ######                                  
option=""     #用户选择序号 
old_text=""   #settext函数修改前内容
new_text=""   #inp函数输入的内容

####### 定义路径  ######
#更新检查程序网址
link_update="https://raw.githubusercontent.com/vincilawyer/Bash/main/install-bash.sh"
#脚本数据文件夹
vincidat_path="/root/myfile"
#用户数据路径
dat_path="$vincidat_path/vinci.dat"
#ssh配置文件路径(查看配置：nano /etc/ssh/sshd_config)                           
path_ssh="/etc/ssh/sshd_config"
#开启消息提醒脚本路径
path_notifier="/root/myfile/notifier.sh"


####### 定义正则表达式 ####### 
#一级域名表达式
domain_regex='^[a-zA-Z0-9-]{1,63}(\.[a-zA-Z]{2,})$'
#二级域名表达式
subdomain_regex='^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$'
#网址域名
web_regex='^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$'
#邮箱表表达式
email_regex='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
#IPV4表达式
ipv4_regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
#IPV6表达式
ipv6_regex='^([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])$'
#ip端口号表达式
port_regex='^([0-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$'
#大陆手机11位手机号表达式
tel_regex='^1[3-9]\d{9}$'
#若干#和空格前置的表达式 
comment_regex='^ *[# ]*'

####### 登录logo样式 ####### 
art=$(cat << "EOF"
  __     __                         _   _           ____                   
  \ \   /"/u          ___          | \ |"|       U /"___|         ___      
    \ \ / //          |_"_|        <|  \| |>      \| | u          |_"_|     
    /\ V /_,-.         | |         U| |\  |u       | |/__          | |      
   U  \_/-(_/        U/| |\u        |_| \_|         \____|       U/| |\u    
     //           .-,_|___|_,-.     ||   \\,-.     _// \\     .-,_|___|_,-. 
    (__)           \_)-' '-(_/      (_")  (_/     (__)(__)     \_)-' '-(_/ 

EOF
)

######   配置模板 ######
function pz { echo "$1=\"$(eval echo \$"$1")\"" ; }
function adddat { tn=$#; ([ -z "$1" ] || (( tn > 1 ))) && quit 1 "添加配置模板错误，请检查是否可能遗漏单引号！" || dat_mod+="$1"; }
adddat '
# 该文件为vinci用户配置文本
# * 表示不可在脚本中修改的常量,变量值需要用双引号包围, #@ 用于分隔变量名称、备注、匹配规则（条件规则和比较规则）。比较规则即为正则表达式的变量名，条件规则为判断\$new_text变量是否符合规则条件，条件需用两个\"\"包裹
Dat_num="\"${#dat_mod}\""                         #版本号*              
$(pz "Domain")                                    #@一级域名#@不用加www#@domain_regex
$(pz "Email")                                     #@邮箱#@#@email_regex
' 


#############################################################################################################################################################################################
##############################################################################   2.脚本启动及退出检查模块  ################################################################################################
############################################################################################################################################################################################
###  说明：exit返回值为1，则为程序错误，要求更新检查程序继续更新本脚本。返回值为3，则用户要求更新检查程序继续更新本脚本。

####### 脚本更新  ####### 
#  说明：输入参数为1则为用户报错或程序自检错误更新
function update {
    clear
    if ((startnum == 2)); then exit 3; fi #未出错程序，用户主动要求返回到更新检查程序继续更新 
    cur_path="$script_path" cur_name="$script_name" wrong="$1" bash <(curl -s -L -H 'Cache-Control: no-cache' "$link_update")
    result=$?
    if [ "$result" == "1" ] ; then        #如果已经更新或不需要继续执行
        exit 0   
    elif [ "$result" == "0" ]; then       #如果没有更新(已是最新版、脚本下载失败、新脚本运行错误)，则继续执行当前脚本
        :
    else                                  #如果更新失败，则继续执行当前脚本
        echo -n "未知错误，请检查！即将返回..."
        countdown 5
    fi
} 

#######   倒计时   ####### 
function countdown {
    local from=$1
    tput sc  # Save the current cursor position
    while [ $from -ge 0 ]; do
        tput rc  # Restore the saved cursor position
        tput el  # clear from cursor to the end of the line
        printf "%02ds" $from  # Print the countdown
        if $(read -s -t 1 -n 1); then break; fi
        ((from--))
    done
    echo
}

####### 执行启动前更新检查  ####### 
[ "$startnum" == 2 ] || update $startnum     #刚更新的程序无需再次检查更新

#######  当用户选择主动退出  #########
function quit() {
   if [ "$1" == "0" ]; then
         clear
         echo -e "${GREED}已退出vinci脚本（V"$Version1"）！${NC}"
         exit 0
   elif [ "$1" == "1" ]; then
       echo "$2"
       [ "$startnum" == "2" ] && exit 1              #检查程序更新脚本后的退出（即无需再次启动检查程序），这里的exit不会执行normal_exit函数
       update 1    
   else
       echo -e "${GREED}非正常退出vinci脚本（V"$Version1"）！${NC}";
   fi
}

#######   当脚本错误退出时，启动更新检查   ####### 
function handle_error() {
    echo "脚本运行出现错误！"
   [ "$startnum" == "2" ] && exit 1              #检查程序更新脚本后的退出（即无需再次启动检查程序），这里的exit不会执行normal_exit函数
   update 1                                     #唤醒程序更新
}

#######   当脚本退出   ####### 
function normal_exit() { : ; }

#######   脚本退出前执行  #######   
trap 'handle_error' ERR
trap 'normal_exit' EXIT

#############################################################################################################################################################################################
##############################################################################   3.主函数  ################################################################################################
############################################################################################################################################################################################
#######   主菜单选项  ######
main_menu=(
    "  1、系统设置"              'page true " 系 统 设 置 " "${system_menu[@]}"'
    "  2、工具箱"                'page true " 工 具 箱 " "${toolbox_menu[@]}"'   
    "  3、UFW防火墙管理"          'page true " UFW 防 火 墙" "${ufw_menu[@]}"'
    "  4、Docker服务"            'page true "Docker" "${docker_menu[@]}"'
    "  5、Nginx服务"             'page true "Nginx" "${nginx_menu[@]}"'
    "  6、X-ui服务"              'page true "X-UI" "${xui_menu[@]}"'
    "  7、Cloudflare服务"        'page true "Cloudflare" "${cf_menu[@]}"'
    "  8、Tor服务"               'page true "Tor" "${tor_menu[@]}"'
    "  9、Frp服务"               'page true "Frp" "${frp_menu[@]}"'
    "  10、Chatgpt-Docker服务"   'page true "Chatgpt-Docker" "${gpt_menu[@]}"'
    "  11、Alist服务"            'page true "Alist" "${alist_menu[@]}"'
    "  12、Rclone服务"            'page true "Rclone" "${rclone_menu[@]}"'
    "  0、退出")

ufw_menu=(
    "  1、返回上一级"            "return"
    "  2、启动\重启防火墙"        "restart ufw"
    "  3、启用防火墙规则"         "ufw enable"
    "  4、停用防火墙规则"         "ufw disable"
    "  5、查看防火墙规则"         "ufw status verbose"
    "  6、查看防火墙运行状况"     "status ufw"
    "  7、停止防火墙"            "stop ufw"
    "  0、退出")      
    
function main {

  #判断系统适配  
  if [ ! $(lsb_release -rs) = "11" ]; then 
  echo "请注意，本脚本是适用于Vulre服务器Debian11系统，用于其他系统或版本时将可能出错！"
  wait
  fi
  
  #检查用户数据文件 
  clear
  update_dat 
  
  #显示一级菜单主页面
  page false " 主 菜 单 " "${main_menu[@]}" 
          
}

#############################################################################################################################################################################################
##############################################################################   4.开 发 工 具  ################################################################################################
############################################################################################################################################################################################

######   页面显示   ######
function page {
   local title="$2"    #页面标题
   local waitcon=$1    #确认是否等待
    while true; do
    # 清除和显示页面样式
    clear
    echo; echo -e "${RED}${art}${NC}"; echo; echo; echo "                   欢迎进入Vinci服务器管理系统(版本V$Version1)"
    echo; echo "=========================== "$2" =============================="; echo
    
    array=("${@:3}")
    menu=()
    cmd=()
    
    #分离菜单和指令
    for (( i=0; i<${#array[@]}; i++ )); do
        if (( i % 2 == 0 )) ; then
            menu+=("${array[$i]}")
            echo "${array[$i]}" 
        else
            cmd+=("${array[$i]}")
        fi
    done
    #获取菜单数量
    menunum=${#menu[@]} 
    echo
    echo -n "  请按序号选择操作: "
    inp false 1 '"[[ "$new_text" =~ ^[0-9]+$ ]] && (( $new_text >= 0 && $new_text <= '$((menunum-1))' ))"'
    [ "$new_text" == "0" ] && quit 0              #如果选择零则退出
    clear 
    eval ${cmd[$((new_text-1))]}  || ( echo "指令执行可能失败，请检查！"; waitcon="true" )
    [ "$waitcon" == "true" ] && wait
done

}

###### 查看程序运行状态 ######
function status {
    if [ -n "$1" ]; then
      systemctl status "$1"
      return
    fi

#如果没有指定则按应用列表输出
apps=(
"ufw"
"docker"
"nginx"
"warp-svc"
"tor"
"frps"
)
   for app in "${apps[@]}"; do  
      zl="systemctl status $app"
      i=1
      while IFS= read -r line; do
          if (( "$i" == 1 )); then
              echo -e "${RED}${line}${NC}"
          else
              echo "$line"
          fi
          i=$((i+1))
      done < <($zl)
   done
}

###### 启动、重启程序 ######
function restart {
   echo "正在重启$1..."
   systemctl restart "$1"
}

###### 停运程序 ######
function stop {
   echo "已停止$1运行！"
   systemctl stop "$1"
}

#######  检验程序安装情况   ########
function installed {
    local software_name=$1
    if which "$software_name" >/dev/null 2>&1; then
       echo -e "${GREEN}该程序已经安装，当前版本号为 $($software_name -v 2>&1)${NC}" 
       if confirm "是否需要重新安装或更新？" "已取消安装！"; then return 0; fi
       return 1
    else
      return 1
    fi
}


#######   等待函数   #######   
function wait {
   if [[ -z "$1" ]]; then
    echo "请按下任意键继续"
   else
    echo $1
   fi
   read -n 1 -s input
}
      

#############################################################################################################################################################################################
##############################################################################   5.文本和输入管理模块  ################################################################################################
############################################################################################################################################################################################

#######   6.1查询文本内容   #######   
function search {
  local start_string="$1"           # 开始文本字符串
  local end_string="$2"             # 结束文本字符串
  local location_string="$3"        # 定位字符串
  local n="${4:-1}"                 # 要输出的匹配结果的索引
  local exact_match="${5:-True}"    # 是否精确匹配结束文本字符串
  local module="${6:-True}"         # 是否在一段代码内寻找定位字符串，false为行内寻找
  local comment="${7:-True}"        # 是否显示注释行
  local is_file="${8:-True}"        # 是否为文件
  local input="$9"                  # 要搜索的内容
  local found_text=""               # 存储找到的文本
  local count=0                     # 匹配计数器
  
  #定义awk的脚本代码
  local awk_script='{
    if($0 ~ location || (mod && mat) ) {
      mat="true"
      if (exact == "true") {
              startPos = index($0, start);
              if (startPos > 0) {
              endPos = index(substr($0, startPos + length(start)), end);
                  if (endPos > 0) {
                      if (++count == num) {
                          print substr($0, startPos + length(start), endPos - 1) ((match($0, /^[[:space:]]*#/) ? " (注释行)" : ""));
                          exit;
                      }
                 }
             }  
      } else {
            startPos = index($0, start);
            if (startPos > 0) {
              endPos = index(substr($0, startPos + length(start)), end);
              if (endPos > 0) {
                  if (++count == num) {
                      if (end == "" ) {
                         print substr($0, startPos + length(start)) ((match($0, /^[[:space:]]*#/) ? " (注释行)" : ""));
                      } else {
                         print substr($0, startPos + length(start), endPos - 1) ((match($0, /^[[:space:]]*#/) ? " (注释行)" : ""));
                      }
                      exit;
                  }    
              } else {  
                  if (++count == num) {  # 输出第 n 个匹配结果
                      print substr($0, startPos + length(start)) ((match($0, /^[[:space:]]*#/) ? " (注释行)" : ""));
                      exit;
                                        }
              }
           }  
      }
    }
  }'
  
  if [ "$is_file" = "true" ]; then    #如果输入的是文件
    found_text=$(awk -v start="$start_string" -v end="$end_string" -v location="$location_string"  -v mod="$module" -v exact="$exact_match" -v num="$n" "$awk_script" "$input")
  else   #如果输入的是字符串
    found_text=$(echo "$input" | awk -v start="$start_string" -v end="$end_string" -v location="$location_string"  -v mod="$module" -v exact="$exact_match" -v num="$n" "$awk_script")
  fi

  if ! $comment; then found_text=${found_text// (注释行)/}; fi
  echo "$found_text"   # 输出找到的文本
}

#######   6.2 替换文本内容   #######   
function replace() {
  local start_string="$1"         # 开始文本字符串
  local end_string="$2"           # 结束文本字符串
  local location_string="$3"      # 定位字符串
  local n="${4:-1}"               # 匹配结果的索引
  local exact_match="${5:-True}"  # 是否精确匹配
  local module="${6:-True}"       # 是否在一段代码内寻找定位字符串，false为行内寻找
  local comment="${7:-fasle}"     # 是否修改注释行
  local is_file="${8:-True}"      # 是否为文件
  local input="$9"                # 要替换的内容
  local input_text="${10}"          # 替换的新文本
  local temp_file="$(mktemp)"
    
  #定义awk的脚本代码
  local awk_script='{
    if($0 ~ location || (mod && mat) ) {
        mat="true"
        if (exact == "true") {
             startPos = index($0, start);
             if (startPos > 0) {
                 endPos = index(substr($0, startPos + length(start)), end);
                  if (endPos > 0) {
                      if (++count == num) {
                          if (comment == "true"  && new == "#" ) {
                              print "#" $0 
                          } else {
                              starttext = substr($0, 1 , startPos - 1 + length(start) );
                              endtext = substr($0, startPos + length(start) + endPos - 1 );
                              line = starttext new endtext;
                              if (comment == "true") {
                                   match(line, /^[ \#]*/)
                                   s = substr(line, RSTART, RLENGTH)
                                   gsub(/\#/, "", s)
                                   line = s substr(line, RLENGTH + 1)
                              }
                              print line;
                          }
                      } else {
                       print $0;
                      }
                  } else {
                       print $0;
                  }
             } else {
                 print $0;
             }
        } else {
             startPos = index($0, start);
             if (startPos > 0) {
                 endPos = index(substr($0, startPos + length(start)), end);
                  if (endPos > 0) {
                      if (++count == num) {
                          if (comment == "true"  && new == "#" ) {
                              print "#" $0 
                          } else {
                              starttext = substr($0, 1 , startPos - 1 + length(start) );
                              endtext = substr($0, startPos + length(start) + endPos - 1 );
                              line = starttext new endtext;
                              if (comment == "true") {
                                   match(line, /^[ \#]*/)
                                   s = substr(line, RSTART, RLENGTH)
                                   gsub(/\#/, "", s)
                                   line = s substr(line, RLENGTH + 1)
                              }
                              print line;
                          }
                      } else {
                       print $0;
                      }
                  } else {
                      if (++count == num) {
                          if (comment == "true"  && new == "#" ) {
                              print "#" $0 
                          } else {
                              starttext = substr($0, 1 , startPos - 1 + length(start) );
                              line = starttext new;
                              if (comment == "true") {
                                   match(line, /^[ \#]*/)
                                   s = substr(line, RSTART, RLENGTH)
                                   gsub(/\#/, "", s)
                                   line = s substr(line, RLENGTH + 1)
                              }
                              print line;
                          }                      
                      } else {
                       print $0;
                      }
                  }
             } else {
                 print $0;
             }        
        }  
      }  else {
           print $0;
      }
}'

  if [ "$is_file" = "true" ]; then    #如果输入的是文件
      awk -v start="$start_string" -v end="$end_string" -v location="$location_string"  -v mod="$module" -v exact="$exact_match" -v new="$input_text" -v comment="$comment" -v num="$n" "$awk_script" "$input" > "$temp_file"
      mv "$temp_file" "$input"
  else   #如果输入的是字符串
      temp_text=$(echo "$input" | awk -v start="$start_string" -v end="$end_string" -v location="$location_string"  -v mod="$module"  -v exact="$exact_match" -v new="$input_text" -v comment="$comment" -v num="$n" "$awk_script")
      echo "$temp_text"   # 输出替换的内容
  fi
}  

#######   6.3修改文本对话框   #######   
function settext {
  local start_string="$1"         # 开始文本字符串
  local end_string="$2"           # 结束文本字符串
  local location_string="$3"      # 定位字符串
  local n="${4:-1}"               # 匹配结果的索引            
  local exact_match="${5:-True}"  # 是否精确匹配结束文本字符串
  local module="${6:-True}"       # 是否在一段代码内寻找定位字符串，false为行内寻找
  local comment="${7:-fasle}"     # 是否修改注释行,false模式下，输入#则内容替换为空字符。输入为"#"，则为#
  local is_file="${8:-True}"      # 是否为文件
  local input="$9"                # 要替换的内容
  local mean="${10}"              # 显示搜索和修改内容的含义
  local mark="${11}"              # 修改内容备注
  #          ${@:12}              # 匹配规则，参照inp函数
  local temp_file="$(mktemp)"
  old_text=""                     # 设置搜中的旧文本作为全局变量（不含“注释行”字样）
  new_text=""                     # 设置输入的新文本作为全局变量（不含前后空格）

     old_text1=$(search "$start_string" "$end_string" "$location_string" "$n" "$exact_match" "$module" "true" "$is_file" "$input")
     old_text=${old_text1// (注释行)/}
     echo
     echo -e "${BLUE}【"$mean"设置】${NC}${GREEN}当前的"$mean"为$([ -z "$old_text1" ] && echo "空" || echo "：$old_text1")${NC}"
     while true; do
         #-r选项告诉read命令不要对反斜杠进行转义，避免误解用户输入。-e选项启用反向搜索功能，这样用户在输入时可以通过向左箭头键或Ctrl + B键来移动光标并修改输入。
         echo -ne "${GREEN}请设置新的$mean（$( [ -n "$mark" ] && echo "$mark,")输入为空则跳过$( [[ $coment == "true" ]] && echo "，输入#则设为注释行" || echo "，输入#则设为空值" )）：${NC}"
         inp true ${@:12} $( [ -n "${13}" ] && echo "#" )  
         if [[ -z "$new_text" ]]; then
             echo -e "${GREEN}已跳过$mean设置${NC}"
             return 1
         else    
            if  [[ $is_file == "true" ]]; then   #如果在文件模式下
                 if [[ "$new_text" == "#" ]] && [[ $comment == "true" ]]; then
                     replace "$start_string" "$end_string" "$location_string" "$n" "$exact_match" "$module" "$comment" "$is_file" "$input" "$new_text"
                     echo -e "${BLUE}已将"$mean"参数设为注释行${NC}"
                     return 0
                 else
                     [[ "$new_text" == "#" ]] && new_text=""
                     [[ "$new_text" == '"#"' ]] && new_text="#"
                     replace  "$start_string" "$end_string" "$location_string" "$n" "$exact_match" "$module" "$comment" "$is_file" "$input" "$new_text"
                     echo -e "${BLUE}"$mean"已修改为"$([ -z "$new_text" ] && echo "空" || echo "：$new_text")"${NC}"
                     return 0
                 fi
            else                           #如果在文本模式下

               :
            fi
         fi
     done  
}    

#######   输入框    ####### 
#说明：1、传入的第一个参数为true则能接受回车输入，第一个参数为false则不能回车输入。参数带有""号字符，则将参数视为具体条件语句，没有""则为普通比较。
#     2、传入的第二个参数为比较模式，1为正则表达式匹配，2为字符串普通匹配。两种模式下，都可以使用条件语句。
#     其余参数均为比较参数
function inp {
    tput sc
    local k="true" #判断参数是否全部为空
    while true; do
        new_text=""
        read new_text
        [ $1 = true ] && [[ -z "$new_text" ]] && tput el && return   #如果$1为true，且输入为空，则完成输入
        for Condition in "${@:3}"; do
           #如果参数为空则继续下一个参数
           [[ -z $Condition ]] && continue   
           k="false"
           # 检查参数是否为条件语句
           if [[ "${Condition:0:1}" == '"' && "${Condition: -1}" == '"' ]]; then   #注意-1前面有空格
                if eval ${Condition:1:-1}; then tput el && return; fi
           # 如果参数为普通字符串
           else
               if [ "$2" == "1" ]; then
                  [[  $new_text =~ $Condition ]] && tput el && return
               elif [ "$2" == "2" ]; then
                  [[ "$new_text" == "$Condition" ]] && tput el && return
               fi
           fi
        done
        [ "$k" == "true" ] && tput el && return
        tput rc
        tput el
        echo
        echo -e "${RED} 输入不正确，请重新输入！${NC}"
        tput rc
   done
}

#######  插入文本 ######
function insert {
    local argtext="$1"           # 参数内容
    local config="$2"           # 配置内容
    local location_string="$3"     #匹配的内容
    local file="$4"                #文件位置
    local findloc=0                #文件中是否找到一个带注释符的匹配内容    
    local lineno=0                 #行号
    local lines=()
    while IFS= read -r line;do
         ((lineno++)) #记住行号
         if [[ $line =~ $location_string ]]; then
              #如果行首不是注释符
              if ! [[ $line =~ ^[[:space:]]*# ]]; then
                  # 插入注释符，并插入新字符串到下一行
                  sed -i "${lineno}s/^/#该行系由vinci脚本修改，原内容为： /" "$file"
                  sed -i "${lineno}a\\$config" "$file"
                  sed -i "${lineno}a\\$argtext" "$file"
                  return
                  
              #如果行首是注释符
              else
                  ((findloc==0)) && findloc=$lineno && continue
                  #如果这不是唯一一行的注释符
                  findloc=0
                  break  
              fi
         fi
    done < "$file"    
    if ! ((findloc==0)); then
       sed -i "${findloc}s/^/#该行系由vinci脚本修改，原内容为： /" "$file"
       sed -i "${findloc}a\\$config" "$file"
       sed -i "${findloc}a\\$argtext" "$file"
       return
    fi
    #如果没找到匹配内容或唯一带有注释匹配内容
    sed -i "${lineno}a\\$config" "$file"
    sed -i "${lineno}a\\$argtext" "$file"
}

#######   是否确认框    #######   
function confirm {
   read -p "$1（Y/N）:" confirm1
   if [[ $confirm1 =~ ^[Yy]$ ]]; then 
   return 1
   fi  
   echo $2
   return 0
}

#############################################################################################################################################################################################
##############################################################################   6.用户数据及应用配置管理模块  ################################################################################################
############################################################################################################################################################################################

#######   创建\更新用户配置数据模板    #######
function update_dat { 
    if ! source $dat_path >/dev/null 2>&1; then   #读取用户数据
        echo "系统无用户数据记录。准备新建用户数据..."
        eval dat_all="\"$dat_mod\"" || quit 1 "更新数据配置模板出错"  #更新数据配置模板
        mkdir $HOME/myfile >/dev/null 2>&1
        echo "$dat_all" > "$dat_path"  #写入数据文件
        echo "初始化数据完成"
        wait
    else
        if ! [ "$Dat_num" == "${#dat_mod}" ] ; then
           echo "配置文件更新中..."
           eval dat_all="\"$dat_mod\"" || quit 1  "更新数据配置模板出错" #更新数据配置模板 
           echo "$dat_all" > "$dat_path" #写入数据文件
           echo "更新完成，可在系统设置中修改参数！"
           wait
        fi
    fi
}

#######   修改数据      #######   
function set_dat { 
  #如果指定配置，则指定修改
    if ! [ $# -eq 0 ]; then
         for arg in "$@"; do
             line=$(search "#@" '' "$arg" 1 false false false true "$dat_path" )            
             IFS=$'\n' readarray -t a <<< $(echo "$line" | sed 's/#@/\n/g') # IFS不可以处理两个字符的分隔符，所以将 #@ 替换为换行符，并用IFS分隔。这里的IFS不在while循环中执行，所以用readarray -t a 会一行一行地读取输入，并将每行数据保存为数组 a 的一个元素。-t 选项会移除每行数据末尾的换行符。空行也会被读取，并作为数组的一个元素。
             rule="$(echo -e "${a[2]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"   #去除规则前后的空格
             if [ -z "$rule" ]; then
             :      #如果是空的，则无需进行判断句的判断
             elif ! [[ "${rule:0:1}" == '"' && "${rule: -1}" == '"' ]]; then   #判断rule是正则表达式变量名还是条件语句,如果是正则表达式变量名则转换为条件语句
                 rule="${!rule}" 
             fi 
             settext "\"" "\"" "$arg" 1 true false false true "$dat_path" "${a[0]}" "${a[1]}" 1 "$rule" 
         done         
    else
    
    #如果没有指定配置，则全文修改
    lines=()
    while IFS= read -r line; do   # IFS用于指定分隔符，IFS= read -r line 的含义是：在没有任何字段分隔符的情况下（即将IFS设置为空），读取一整行内容并赋值给变量line。与下面的IFS不同，这个命令在一个 while 循环中执行，每次循环都会读取 line1 中的一行，直到 line1 中的所有行都被读取完毕。
         if [[ ! $line =~ "=" ]] || [[ $line =~ ^([[:space:]]*[#]+|[#]+) ]] || [[ $line =~ \*([[:space:]]*|$) ]] ; then continue ; fi  #跳过#开头和*结尾的行
         lines+=("$line")    #将每行文本转化为数组     
    done < "$dat_path"
    
    # 因为在上面含有IFS= read的循环中，没法再次read到用户的输入数据，因此在循环外处理数据
    for line in "${lines[@]}"; do   
         a=()
         IFS=$'\n' readarray -t a <<< $(echo "$line" | sed 's/#@/\n/g') # IFS不可以处理两个字符的分隔符，所以将 #@ 替换为换行符，并用IFS分隔。这里的IFS不在while循环中执行，所以用readarray -t a 会一行一行地读取输入，并将每行数据保存为数组 a 的一个元素。-t 选项会移除每行数据末尾的换行符。空行也会被读取，并作为数组的一个元素。
         IFS="=" read -ra b <<< "$line" 
         rule="$(echo -e "${a[3]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"   #去除规则前后的空格
         if [ -z "$rule" ]; then   #如果是空的，则无需进行判断句的判断
             :      
         elif ! [[ "${rule:0:1}" == '"' && "${rule: -1}" == '"' ]]; then   #判断rule是正则表达式变量名还是条件语句,如果是正则表达式变量名则转换为条件语句
             rule=${!rule}   
         fi
         settext "${b[0]}=\"" '"' "" 1 true false false true "$dat_path" "${a[1]}" "${a[2]}" 1 "$rule" 
    done
    fi
    source "$dat_path"   #重新载入数据
    echo
    echo "已修改配置完毕！"
}

#######  应用配置更新   #######   
function update_config {
    lines=()
    local ct=0      #已修改配置的数量
    local ft=0      #修改失败的数量
    while IFS= read -r line; do     
         lines+=("$line")    #将每行文本转化为数组     
    done < "$1" 

    for index in "${!lines[@]}"; do   
         line1=${lines[$index]}
         linenum=$((index+1))            #配置行号
         line2=${lines[$linenum]}
         [[ "$line1" == *'#￥#@'* ]] || continue      #如果没有找到参数行，则继续查找
         [[ "$line2" =~ ^[[:space:]]*# ]] && continue      #如果配置行是注释行，则继续查找
         a=()
         IFS=$'\n' readarray -t a <<< $(echo "$line1" | sed 's/#@/\n/g')    # IFS不可以处理两个字符的分隔符，所以将 #@ 替换为换行符，并用IFS分隔。
         varname="$(echo -e "${a[4]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"   #去除变量名的前后空格
         echo 
         #如果变量存在
         if [ -v $varname ]; then
            echo "已将配置由：$line2"
            lines[$linenum]=$(replace "${a[2]}" "${a[3]}" "" 1 false false false false "${line2}"  "${!varname}")
            echo -e "更新为：${BLUE}${lines[$linenum]}${NC}"
            echo
            ct=$(( ct + 1 ))
            
         #如果变量不存在
         else
            echo -e "${RED}配置修改失败：$line2${NC}"
            echo -e "${RED}用户数据中未找到${a[1]}的变量名：$varname${NC}"
            echo
            ft=$(( ft + 1 ))
         fi
    done
        if (( ct > 0 )); then
           printf "%s\n" "${lines[@]}" > "$1"
           echo -e "${BLUE}已完成$ct条配置的修改更新${NC}"
           echo -e "${RED}有$ft条配置更新失败${NC}"
           return 0
        else
           echo -e "${RED}配置更新失败，未找到配置行或配置值！${NC}"
           return 1
        fi
} 


#############################################################################################################################################################################################
##############################################################################    7.系统工具  ################################################################################################
############################################################################################################################################################################################
### 菜单选项 ###
system_menu=(
    "  1、返回上一级"                "return"
    "  2、查看所有重要程序运行状态"    "status"
    "  3、本机ip信息"               "ipinfo"
    "  4、修改配置参数"              "set_dat"
    "  5、查看配置参数文件"           "nano /root/myfile/vinci.dat"
    "  6、修改SSH登录端口和登录密码"   "change_ssh_port; change_login_password"
    "  7、更新脚本"                  'update; [ "$?" == "2" ] && echo "当前版本为最新版，无需更新！"'
    "  0、退出" )    

 
    
###### 查看ip信息 ######
function ipinfo {
  echo "本机IP信息："
  hostname -I
  
#代理端口列表
apps=(
"Warp"
"Tor"
)
   echo "网络状况"
   echo "代理IP信息："
   for app in "${apps[@]}"; do  
       port_value=$(eval echo \$"${app}_port")
       echo "$app(端口$port_value)的代理IP地址为："
       curl --socks5-hostname localhost:"$port_value" http://api.ipify.org
      echo
   done
}

#######  修改SSH端口    #######  
function change_ssh_port {
    if settext "Port " " " "" 1 false false true true $path_ssh "SSH端口" "0-65535" 1 $port_regex; then
          echo -e "${GREEN}已正从防火墙规则中删除原SSH端口号：$old_text${NC}"
          ufw delete allow $old_text/tcp   
          echo -e "${GREEN}正在将新端口"$new_text"添加进防火墙规则中。${NC}"
          ufw allow "$new_text"/tcp  
          systemctl restart sshd
          echo -e "${GREEN}当前防火墙运行规则及状态为：${NC}"
          ufw status
    fi  
}

#######  修改登录密码    ####### 
function change_login_password {
    # 询问账户密码 
    if settext "@" "@" "" "" "" "" "" false "@********@" "SSH登录密码" "至少8位" 1 ".{8,}"; then 
         #修改账户密码
         chpasswd_output=$(echo "root:$new_text" | chpasswd 2>&1)
         if echo "$chpasswd_output" | grep -q "BAD PASSWORD" >/dev/null 2>&1; then
            echo -e "${RED}SSH登录密码修改失败,错误原因：${NC}"
            echo "$chpasswd_output" >&2
         else
            echo -e "${GREEN}SSH登录密码已修改成功！新密码为:$new_text,请妥善保管！${NC}"
         fi
   fi
}
#############################################################################################################################################################################################
##############################################################################    8.工具箱  ################################################################################################
############################################################################################################################################################################################
#### 菜单栏 ###
toolbox_menu=(
    "  1、返回上一级"      "return"
    "  2、设置微信通知推送" ""
    "  0、退出")   
####  参数  ###
webhook='https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=615a90ac-4d8a-48f1-b396-1f4bfbc650cd'

###### 消息推送 ######
function notifier {
# 使用curl发送POST请求，这里使用的JSON格式的数据
curl "$webhook" \
     -H 'Content-Type: application/json' \
     -d "{
     \"msgtype\": \"text\",
     \"text\": {
         \"content\": \"【服务器信息】\n$1\"
     }
}" >/dev/null 2>&1
}

###### 作废消息推送 ######
function notifier_service {
cat > "$path_notifier" <<EOF
#!/bin/sh
# 获取当前时间
TIME=\$(date '+%Y-%m-%d %H:%M:%S')
# 使用curl发送POST请求，这里使用的JSON格式的数据
curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=615a90ac-4d8a-48f1-b396-1f4bfbc650cd' \
     -H 'Content-Type: application/json' \
     -d "
{
     \"msgtype\": \"text\",
     \"text\": {
         \"content\": \"\$TIME\n【服务器已开机】\"
     }
}" > /dev/null
EOF
chmod +x "$path_notifier"
#一、编辑文本，把执行脚本notifier.sh写进sudo nano /root/.bashrc中,即可在使用bash登录ssh时自动执行
#二、创建文件 /etc/systemd/system/notifier.service 并添加如下内容
#[Unit]
#Description=Boot Notification Service
#[Service]
#ExecStart=$path_notifier       #此次为脚本保存路径
#[Install]
#WantedBy=multi-user.target
#保存以上内容并设置权限sudo chmod 644 /etc/systemd/system/notifier.service
#输入sudo systemctl daemon-reload
#sudo systemctl start notifier.service即可启动该服务
#设置开机自启动sudo systemctl enable notifier.service即可在开机时执行脚本
#三、关于关机通知，systemd并没有提供一个内置的方式来在关机时运行脚本。一种可行的方式是创建一个服务，在这个服务停止时运行关机通知脚本。
}

####### 一键搭建服务端的函数 ######
function one_step {
   echo "维护"
   return
   if confirm "是否一键搭建科学上网服务端？" "已取消一键搭建科学上网服务端"; then return; fi
   echo "正在安装X-ui面板"
   install_Xui
   wait "点击任意键安装Nginx"
   install_Nginx
   wait "点击任意键安装Warp"
   install_Warp
   echo "请：
   1、在x-ui中自行申请SSL
   2、在x-ui面板中调整xray模板、面板设置，并创建节点"
}

#############################################################################################################################################################################################
##############################################################################   9.Docker  ################################################################################################
############################################################################################################################################################################################
###   说明：查看容器docker ps -a；下载镜像 docker pull ；删除镜像 docker rmi ； 运行容器 docker run ；停止容器 docker stop container_id ；删除 docker rm container_id ；恢复容器 docker start container_id
### 菜单栏
docker_menu=(
    "  1、返回上一级"            "return"
    "  2、安装Docker"           "install_Docker"
    "  3、启动\重启Docker"       "restart docker"
    "  4、查看Docker容器"        'echo "Docker容器状况：" && docker ps -a && echo; echo "提示：可使用docker stop 或 docker rm 语句加容器 ID 或者名称来停止容器的运行或者删除容器 "'
    "  5、查看Docker运行状况"     "status docker"
    "  6、停止Docker运行"        "stop docker"
    "  7、删除所有容器"          'confirm "是否删除所有Docker容器？" "已取消删除容器" || ( docker stop $(docker ps -a -q) &&  docker rm $(docker ps -a -q) && echo "已删除所有容器" )'
    "  0、退出")
    
#######  安装Docker及依赖包  #######
function install_Docker {
     installed "docker" && return
    
    # 安装docker，具体在https://docs.docker.com/engine/install/debian/中查看说明教程
    # 卸载冲突包
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    # 更新apt包索引并安装包以允许apt通过 HTTPS 使用存储库：
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg

    #添加Docker官方GPG密钥：
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    #使用以下命令设置存储库：
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    #更新apt包索引：
    sudo apt-get update
    #安装最新版本 Docker 引擎、containerd 和 Docker Compose。
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

#############################################################################################################################################################################################
##############################################################################   10.Nginx模块  ################################################################################################
############################################################################################################################################################################################
### 菜单栏  ####
nginx_menu=(
    "  1、返回上一级"              "return"
    "  2、安装Nginx"              "install_Nginx"
    "  3、启动\重启Nginx"          "restart "nginx""
    "  4、设置Nginx配置"           "echo 0"
    "  5、查看Nginx运行状况"        "status nginx"
    "  6、查看Nginx日志"            "nano /var/log/nginx/access.log"
    "  7、停止Nginx"               "stop nginx"
    "  0、退出")

### 路径 ###
#nginx配置文件网址
link_nginx="https://raw.githubusercontent.com/vincilawyer/Bash/main/nginx/default.conf"
#nginx配置文件路径 (查看配置：nano /etc/nginx/conf.d/default.conf)                      
path_nginx="/etc/nginx/conf.d/default.conf" 
#nginx日志文件路径
log_nginx="/var/log/nginx/access.log"
#nginx 80端口默认服务块文件路径
default_nginx="/etc/nginx/sites-enabled/default"



####### 安装Nginx ######
function install_Nginx {
        installed "nginx" && return    #检验安装
        echo -e "${GREEN}正在更新包列表${NC}"
        apt-get update
        echo -e "${GREEN}包列表更新完成${NC}"
        apt-get install nginx -y
        echo -e "${GREEN}Nginx 安装完成，版本号为 $(nginx -v 2>&1)。${NC}"
        echo -e "${GREEN}正在调整防火墙规则，放开80、443端口。${NC}"
        ufw allow http && ufw allow https 
        echo -e "${GREEN}正在调整Nginx配置${NC}"
        download_nginx_config
        echo "" > $default_nginx   # 清空nginx对80端口默认服务块的配置内容

}

####### 从github下载更新Nginx配置文件 ####### 
function download_nginx_config {
      if confirm "是否从Github下载更新Nginx配置文件？此举动将覆盖原配置文件" "已取消下载更新Nginx配置文件"; then return; fi
      echo -e "${GREEN}正在载入：${NC}"
      if wget $link_nginx -O $path_nginx; then 
         echo -e "${GREEN}载入完毕，第一次使用请设置配置：${NC}"
        set_nginx_config
    else
            echo -e "${GREEN}下载失败，请检查！${NC}"
         fi       
}

####### 设置Nginx配置 ####### 
function set_nginx_config {
     echo "维护中，请手动导入配置！"
     return
       if ! [ -x "$(command -v nginx)" ]; then
          echo -e "${RED}Nginx尚未安装，请先进行安装！${NC}"
       fi
       current_domain=$(search "server_name " ";" 1 $path_nginx true false)
       set "ssl_certificate " "/$current_domain" 1 $path_nginx true "SSL证书存放路径"
       current_ssl_path=$(search "ssl_certificate " "$current_domain" 1 $path_nginx true false)
       if set "server_name " ";" 1 $path_nginx true "VPS域名" "" true "^[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$"; then
           replace  "$current_ssl_path" ".cer;" 1 "$text2" $path_nginx true
           replace  "$current_ssl_path" ".key;" 1 "$text2" $path_nginx true
       fi
       if set "https://" "; #伪装网址" 1 $path_nginx true "伪装域名" "" true "^[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$"; then
           replace  "sub_filter \"" "\"" 1 "$text2" $path_nginx true
           replace  "proxy_set_header Host \"" "\"" 1 "$text2" $path_nginx true
       fi
       set "location /ray-" " {" 1 $path_nginx true "xray分流路径" "省略/ray-前缀，"
       set "http://127.0.0.1:" "; #Xray端口" 1 $path_nginx true "Xray监听端口" "0-65535，" true "^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"
       set "location /xui-" " {" 1 $path_nginx true "x-ui面板分流路径" "省略/xui-前缀，"
       set "http://127.0.0.1:" "; #xui端口" 1 $path_nginx true "X-ui监听端口" "0-65535，" true "^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"
       echo "正在重启Nginx..."
       if nginx -t &> /dev/null; then
          systemctl restart nginx
          return
       fi
       echo "Nginx配置文件存在错误，请检查并修改后重启！"
}   
####### 从github下载网页文件 ####### 
function download_html {
   echo "维护中..."
   return
   if confirm "此操作将从Github的vincilawyer/Bash/nginx/html目录下载入网页文件，并覆盖原网页文件！" "已取消下载更新网页文件"; then return; fi
    #输入主题名称
    read -p "请输入网页主题名称（例如Moon）：" input
    if [[ -z $input ]]; then 
        echo "已取消操作!"
        return
    fi
    echo "正在下载网页zip压缩包..."

    #开始下载并覆盖
    if wget "$link_html$input".zip -O /home/"$input".zip; then
       echo "压缩包下载完成，开始解压"
       unzip /home/"$input".zip -d /home
       path_html=$(search "root" " ")
       echo "开始覆盖原网页文件"
       rm -r "$path_html"/*  >/dev/null
       mv /home/"$input"/* "$path_html"/
       echo "已更新网页文件！"
       rm -r /home/"$input".zip
       rm -r /home/"$input"
       rm -rf /home/__MACOSX >/dev/null
       echo "已清除压缩包！"
   else
       echo "下载失败，请检查文件名称或网络！"
   fi    
}

                                                                         
#######  使用Certbot申请SSL证书的函数 ####### 
function apply_ssl_certificate {
   echo "维护中"
   return
    # 输入域名
    while true; do
        read -p "$(echo -e ${BLUE}"请输入申请SSL证书域名（不加www.）: ${NC}")" domain_name
        if [[ -z $domain_name ]]; then
          echo -e "${RED}未输入域名，退出申请操作${NC}"
          return
        elif [[ $domain_name =~ ^[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo -e "${RED}输入格式不正确，请重新输入${NC}"
        fi
    done

    # 输入邮箱
    while true; do
        read -p "$(echo -e ${BLUE}"请输入申请SSL证书邮箱: ${NC}")" email
        if [[ -z $email || ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo -e "${RED}输入格式不正确，请重新输入${NC}"
        else
            break
        fi
    done
    
  
    # 停止nginx运行
    if [ -x "$(command -v nginx)" ]; then
       systemctl stop nginx
       echo -e "${GREEN}为了防止80端口被占用，已停止nginx运行${NC}"
    fi  
  
    #关闭防火墙
    ufw disable 
    echo -e "${GREEN}为了防止证书申请失败，已关闭防火墙${NC}"

    # 检查并安装Certbot
    if [ -x "$(command -v certbot)" ]; then
      echo -e "${GREEN}本机已安装Certbot，无需重复安装，即将申请SSL证书...${NC}"
    else
      echo -e "${GREEN}正在更新包列表${NC}"
      sudo apt update
      echo -e "${GREEN}包列表更新完成${NC}"
      echo -e "${GREEN}正在安装Certbot...${NC}"
      apt install certbot certbot -y
      echo -e "${GREEN}Certbot安装完成，即将申请SSL证书...${NC}"
    fi
  
    # 申请证书
    certbot certonly --standalone --agree-tos -n -d $domain_name -m $email
    
    # 判断申请结果
    if check_ssl_certificate "$domain_name"; then
        echo -e "${GREEN}SSL证书申请已完成！${NC}"
        # 证书自动续约
        echo "0 0 1 */2 * service nginx stop; certbot renew; service nginx start;" | crontab
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}未成功启动证书自动续约${NC}"
        else
            echo -e "${GREEN}已启动证书自动续约${NC}"
        fi
    else
        echo -e "${RED}SSL证书申请失败！${NC}"
    fi
    
    # 重启nginx
    if [ -x "$(command -v nginx)" ]; then
       echo -e "${GREEN}正常恢复nginx运行${NC}"  
       systemctl start nginx
    fi  

    #重启防火墙
    echo -e "${GREEN}正在恢复防火墙运行${NC}"  
    ufw --force enable
}

#######  判断Certbot申请的SSL证书是否存在  ####### 
function check_ssl_certificate {
   echo "维护中"
   return
    domain_name="$1"
    ssl_path="$2"
    #搜索SSL证书
    search_result=$(find "$2/" -name fullchain.pem -print0 | xargs -0 grep -l "$domain_name" 2>/dev/null)
    if [[ -z "$search_result" ]]; then
      return false
    else
      return true
    fi
}

      
#############################################################################################################################################################################################
##############################################################################   11.Xui模块  ################################################################################################
############################################################################################################################################################################################
### 菜单栏 ###
  xui_menu=(
    "  1、返回上一级"                     "return"
    "  2、安装\更新Xui面板"               "install_Xui"
    "  3、进入Xui面板管理（指令:x-ui）"     "x-ui"
    "  0、退出" )     
    
###### 安装X-ui的函数 ######
function install_Xui {
   if which "x-ui" >/dev/null 2>&1; then
      echo "Xui面板已经安装！"
   else
      bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
   fi
}

#############################################################################################################################################################################################
##############################################################################   12.Cloudflare模块  ################################################################################################
############################################################################################################################################################################################
######   参数配置   ######
adddat '
##### Cloudflare ######
$(pz "Cloudflare_api_key")                        #@Cloudflare Api
$(pz "Warp_port")                                 #@Warp监听端口#@0-65535#@port_regex
'
#### 菜单栏
cf_menu=(
    "  1、返回上一级"               "return"
    "  2、Cloudflare DNS配置"      'cfdns; continue'
    "  3、修改CF账户配置"           "set_cfdns"
    "  4、下载CFWarp"              "install_Warp"
    "  5、启动\重启CFWarp"          "restart warp-svc"
    "  6、查看CFWarp运行状况"        "status warp-svc"
    "  7、停用CFWarp"              "stop warp-svc"
    "  0、退出")      
    
###### Cf dns配置 ######
function cfdns {
    if ! which "jq" >/dev/null 2>&1; then
      echo "正在安装依赖软件JQ..."
      apt update
      apt install jq -y
      echo "依赖件JQ已安装完成！"
    fi
    while true; do 
    # 获取区域标识符
    zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$Domain" \
     -H "X-Auth-Email: $Email" \
     -H "X-Auth-Key: $Cloudflare_api_key" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')
    #如果账户不存在则退出
    if [ "$zone_identifier" == "null" ]; then
       echo "未找到您的Cloudflare账户\域名，请检查配置。"
       wait
       return
    fi
    dns_records="$(get_all_dns_records $zone_identifier)"
    echo "$dns_records"
    echo
    echo
    # 询问用户要进行的操作
    echo "  操作选项："
    echo "  1. 删除DNS记录修改或增加DNS记录"
    echo "  2. 修改或增加DNS记录"
    echo "  3. 返回"
    echo "  0. 退出"
    echo ""
    echo -n "  请选择要进行的操作：" 
    inp false 2 {0..3}
    case $new_text in  
1)#删除DNS记录 
        clear
        echo "$dns_records"
        echo
        echo
        echo -n "请输入要删除的DNS记录名称（例如 www,输入为空则跳过）："
        inp true 1 '^[a-zA-Z0-9]+'
        [ -z $new_text ] && clear && continue 
        record_name=$new_text
        # 获取记录标识符
        record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name.$Domain" \
             -H "X-Auth-Email: $Email" \
             -H "X-Auth-Key: $Cloudflare_api_key" \
             -H "Content-Type: application/json" | jq -r '.result[0].id')
        
        clear
        # 如果记录标识符为空，则表示未找到该记录
        if [ "$record_identifier" == "null" ]; then
            echo -e "${RED}未找到该DNS记录，请重新操作。${NC}"
            continue
        else
            # 删除记录
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                 -H "X-Auth-Email: $Email" \
                 -H "X-Auth-Key: $Cloudflare_api_key" \
                 -H "Content-Type: application/json"
            echo
            echo "已成功删除DNS记录: $record_name.$Domain"
            continue
        fi;;
2)# 修改或增加DNS记录
        clear
        echo "$dns_records"
        echo
        echo
        echo -n "请输入要修改或增加的DNS记录名称（例如 www，输入空则跳过）："
        inp true 1 '^[a-zA-Z0-9]+' &&[ -z $new_text ] && clear && continue 
        record_name="$new_text"
        echo -n "请输入要绑定ip地址（输入空则跳过,输入#则为本机IP）："
        inp true 1 "$ipv4_regex" '[ "$new_text" == "#" ]' && [ -z $new_text ] && clear && continue 
        if [ "$new_text" == "#" ]; then
           record_content=$(curl -s https://ipinfo.io/ip)
        else
           record_content="$new_text"
        fi
        read -p "是否启用Cloudflare CDN代理？（Y/N）" enable_proxy
        if [[ $enable_proxy =~ ^[Yy]$ ]]; then
            proxy="true"
        else
            proxy="false"
        fi
          
            # 获取记录标识符
            record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name.$Domain" \
                 -H "X-Auth-Email: $Email" \
                 -H "X-Auth-Key: $Cloudflare_api_key" \
                 -H "Content-Type: application/json" | jq -r '.result[0].id')
            clear 
            # 如果记录标识符为空，则创建新记录
            if [ "$record_identifier" == "null" ]; then
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" \
                     -H "X-Auth-Email: $Email" \
                     -H "X-Auth-Key: $Cloudflare_api_key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'"$record_name"'","content":"'"$record_content"'","proxied":'"$proxy"'}'
                echo
                echo "已成功添加记录 $record_name.$Domain"
                continue
            else
                # 如果记录标识符不为空，则更新现有记录
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                     -H "X-Auth-Email: $Email" \
                     -H "X-Auth-Key: $Cloudflare_api_key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'"$record_name"'","content":"'"$record_content"'","proxied":'"$proxy"'}'
                echo
                echo "已成功更新记录 $record_name.$Domain"
                continue
           fi;;
     3) return;;
     0) quit 0
        clear;;
  esac
  wait
  done
}

######  获取并显示所有DNS解析记录、CDN代理状态和TTL  ######
function get_all_dns_records {
    dns_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$1/dns_records?type=A" \
         -H "X-Auth-Email: $Email" \
         -H "X-Auth-Key: $Cloudflare_api_key" \
         -H "Content-Type: application/json" | jq -r '.result[] | [.name, .content, .proxied, .ttl] | @tsv')
       echo "——————————Cloudflare DNS解析编辑器V3————————————"
       echo "以下为$Domain域名当前的所有DNS解析记录："
       echo
       echo "            域名                             ip        CDN状态  TTL"
       echo "$dns_records"
}

######  设置cfDNS配置 ######
function set_cfdns {
local config=(
"Domain"
"Email"
"Cloudflare_api_key"
)
    set_dat "${config[@]}"
}
###### 安装cf warp套 ######
function install_Warp {
     installed "warp-cli" && return
        #先安装WARP仓库GPG密钥：
        echo -e "${GREEN}正在安装WARP仓库GPG 密钥${NC}"
        curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
        #添加WARP源：
        echo -e "${GREEN}正在添加WARP源${NC}"
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
        #更新源
        echo -e "${GREEN}正在更新包列表${NC}"
        sudo apt update
        #安装Warp
        echo -e "${GREEN}开始安装Warp${NC}"
        apt install cloudflare-warp -y
        #注册WARP：
        echo -e "${GREEN}注册WARP中，请输入y予以确认${NC}"
        warp-cli register
        #设置为代理模式（一定要先设置）：
        echo -e "${GREEN}设置代理模式${NC}"
        warp-cli set-mode proxy
        #连接WARP：
        echo -e "${GREEN}连接WARP${NC}"
        warp-cli connect
        sleep 2
        #查询代理后的IP地址：
        echo -e "${GREEN}Warp 安装完成，代理IP地址为：${NC}"
        curl ifconfig.me --proxy socks5://127.0.0.1:40000
        echo
}

#############################################################################################################################################################################################
##############################################################################   13.Tor模块  ################################################################################################
############################################################################################################################################################################################
######   参数配置   ######
path_tor="/etc/tor/torrc"
adddat '
##### Tor ######
$(pz "Tor_port")                                  #@Tor监听端口#@0-65535#@port_regex
'
##### 菜单栏 #####
tor_menu=(
    "  1、返回上一级"                  "return"
    "  2、安装Tor"                   "install_Tor"
    "  3、启动\重启Tor"               "restart tor; echo;  ipinfo"
    "  4、设置Tor配置"                "set_tor_config"
    "  5、查看Tor运行状况"             "status tor"
    "  6、停用Tor"                    "stop tor"
    "  0、退出")

###### 安装Tor的函数 ######
function install_Tor {
    installed "tor" && return 
    echo -e "${GREEN}正在更新包列表${NC}"
    sudo apt update
    echo -e "${GREEN}开始安装Tor${NC}"
    apt install tor -y
    #设置开机自启动
    systemctl enable tor
    #配置初始化
    initialize_tor
    sleep 2
    ipinfo
}

##### 初始化tor配置 ######
function initialize_tor {
    insert "#￥#@Tor监听端口#@SocksPort #@ #@Tor_port" "SocksPort 50000 " "SocksPort " "$path_tor"
}

###### 设置Tor配置 ######
function set_tor_config {
local conf=(
"Tor_port"
)
    set_dat ${conf[@]}
    if update_config "$path_tor"; then
       confirm "是否重启tor并适用新配置？" "已取消重启！" || (restart tor && sleep 3 && ipinfo)
    fi  
}

#############################################################################################################################################################################################
##############################################################################   13.Frp模块  ################################################################################################
############################################################################################################################################################################################
##### 菜单栏 #####
  frp_menu=(
    "  1、返回上一级"                    "return"
    "  2、安装Frp"                     "install_Frp"
    "  3、启动\重启Frp"                 "restart frps"
    "  4、设置Frp配置"                  "set_Frp"
    "  5、查看Frp运行状况"               "status frps"
    "  6、停用Frp"                      "stop frps"
    "  0、退出")
    
######   参数配置   ######
adddat '
#####Frps######
$(pz "bind_port")                              #@服务端监听端口#@0-65535#@port_regex 
$(pz "vhost_http_port")                        #@HTTPS监听的端口#@0-65535#@port_regex 
$(pz "token")                                   #@授权码#@数字
$(pz "dashboard_port")                           #@服务端仪表板端口#@0-65535#@port_regex 
$(pz "dashboard_user")                             #@仪表板登录用户名
$(pz "dashboard_pwd")                              #@仪表板登录密码
'

#frp配置文件路径（查看配置：nano /etc/frp/frps.ini）  
path_frp="/etc/frp"


###### 安装Frp的函数 ######
function install_Frp {
   installed "frps" && return 
        # 获取最新的 frp 版本
        frp_version=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4)
        # 获取Linux amd64版本的tar.gz文件名
        file_name=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | jq -r '.assets[] | select(.name | contains("linux_amd64")) | .name')
        # 下载最新版本的 frp
        wget https://github.com/fatedier/frp/releases/download/$frp_version/$file_name
        # 解压下载的文件
        tar -xvzf $file_name
        rm $file_name
        
        # 把frps加入systemd
        mv $(echo $file_name | sed 's/.tar.gz//')/frps /usr/bin/
        mkdir -p $path_frp
        mv $(echo $file_name | sed 's/.tar.gz//')/frps.ini $path_frp
        rm -r $(echo $file_name | sed 's/.tar.gz//')
        # 注意文件中的路径
        cat > /usr/lib/systemd/system/frps.service <<EOF
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/frps -c /etc/frp/frps.ini

[Install]
WantedBy=multi-user.target
EOF
        initialize_frp
}

###### 初始化Frp配置 ######
function initialize_frp {
cat > "$path_frp/frps.ini" <<EOF
[common]
#￥#@服务端监听端口#@= #@ #@bind_port
bind_port = 27277
#￥#@HTTP监听端口#@= #@ #@vhost_http_port
vhost_http_port = 15678
#￥#@授权值#@= #@ #@token
token = 58451920
#￥#@服务端仪表板端口#@= #@ #@dashboard_port
dashboard_port = 21211          
#￥#@仪表板登录用户名#@= #@ #@dashboard_user
dashboard_user = admin          
#￥#@仪表板登录密码#@= #@ #@dashboard_pwd
dashboard_pwd = admin          
EOF
}

###### 设置frp ######
function set_Frp {
local conf=(
"bind_port"
"vhost_http_port"
"token"
"dashboard_port"
"dashboard_user" 
"dashboard_pwd"
)
    set_dat ${conf[@]}
    if update_config "$path_frp/frps.ini"; then
       confirm "是否重启Frps并适用新配置？" "已取消重启！" || restart frps
    fi  
  
}



#############################################################################################################################################################################################
##############################################################################   15.Chatgpt—Docker  ################################################################################################
############################################################################################################################################################################################
######   参数配置   ######
adddat '
#####Chatgpt-docker######
$(pz "Gpt_port")                              #@Chatgpt本地端口#@0-65535#@port_regex 
$(pz "Chatgpt_api_key")                        #@Chatgpt Api
$(pz "Gpt_code")                               #@授权码
$(pz "Proxy_model")                           #@接口代理模式#@1为正向代理、2为反向代理#@\"[[ \$new_text =~ ^(1|2)\$ ]]\"
$(pz "BASE_URL")                               #@OpenAI接口代理URL#@默认接口为https://api.openai.com#@web_regex
$(pz "PROXY_URL")                              #@Chatgpt本地代理地址#@需要加http前缀#@web_regex
Chatgpt_image=\"yidadaa/chatgpt-next-web\"       #Chat镜像名称*
Chatgpt_name=\"chatgpt\"                                    #Chat容器名称*
'
##### 菜单栏 #####
gpt_menu=(
    "  1、返回上一级"                        "return"
    "  2、下载\更新Chatgpt"                 "pull_gpt"
    "  3、启动\重启动Chatgpt"               "docker start $Chatgpt_name"
    "  4、运行\重运行Chatgpt容器"            "run_gpt"
    "  5、设置Chatgpt配置"                  "set_gpt"
    "  6、查看Chatgpt运行状况"               'docker inspect $Chatgpt_name'
    "  7、停用Chatgpt"                     'confirm "是否停止运行Chatgpt？" "已取消！" || docker stop $Chatgpt_name'
    "  0、退出")                     


######  下载 chatgpt-next-web 镜像 ######
function pull_gpt {
docker pull yidadaa/chatgpt-next-web
}

######  运行chatgpt-next-web 镜像 ######
function run_gpt {
    docker stop $Chatgpt_name >/dev/null 2>&1 && echo "正在重置chatgpt容器..."
    docker rm $Chatgpt_name >/dev/null 2>&1
    if (( Proxy_model==1 )); then 
        if docker run -d --name $Chatgpt_name --restart=always -p 3000:$Gpt_port \
           -e OPENAI_API_KEY="$Chatgpt_api_key" \
           -e CODE="$Gpt_code" \
           --net=host \
           -e PROXY_URL="$PROXY_URL" \
           $Chatgpt_image
       then
           echo "Chatgpt启动成功！"
       else 
        echo "启动失败，请重新设置参数配置"
       fi  
    elif (( Proxy_model==2 )); then 
        if docker run -d  --name $Chatgpt_name --restart=always -p 3000:$Gpt_port \
           -e OPENAI_API_KEY="$Chatgpt_api_key" \
           -e CODE="$Gpt_code" \
           -e BASE_URL="$BASE_URL" \
           $Chatgpt_image
       then
           echo "Chatgpt启动成功！"
       else 
        echo "启动失败，请重新设置参数配置"
       fi  

    fi
}

######  设置chatgpt配置 ######
function set_gpt {
local conf=(
"Gpt_code"
"Chatgpt_api_key"
"Gpt_port"
"Proxy_model"
"BASE_URL"
"PROXY_URL" 
)
    set_dat ${conf[@]}
    if confirm "是否启动Chatgpt并适用最新配置？" "已取消启动"; then return; fi
    run_gpt
}

#############################################################################################################################################################################################
##############################################################################   Alist  ################################################################################################
############################################################################################################################################################################################
### 菜单栏
alist_menu=(
    "  1、返回上一级"            "return"
    "  2、安装Alist"            'curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install'
    "  3、更新Alist"            'curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s update'
    "  4、启动\重启Alist"        'restart alist'
    "  5、查看Alist运行状况"     "status alist"
    "  6、停止Alist运行"        "stop alist"
    "  7、删除Alist"          'confirm "是否删除Alist？" "已取消删除Alist" || ( curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s uninstall && echo "已删除Alist" )'
    "  0、退出")
    
#############################################################################################################################################################################################
##############################################################################   Rclone  ################################################################################################
############################################################################################################################################################################################
### 菜单栏
rclone_menu=(
    "  1、返回上一级"            "return"
    "  2、安装Rclone"            'curl https://rclone.org/install.sh | sudo bash'
    "  3、Rclone配置"            'rclone config'
    "  4、将Baidu网盘书库更新至Onedrive"            'baidutoonebook'
    "  5、将Onedrive书库更新至Baidu网盘"            'onetobaidubook'
    "  6、将Baidu网盘指定文件更新至Onedrive"            'baidutoone'
    "  7、将Onedrive指定文件更新至Baidu网盘"            'onetobaidu'
    "  8、Rclone使用指引"                       'echo "指令指引";echo "列出文件夹: rclone lsd onedrive:";echo "复制文件：rclone copy";echo "同步文件：rclone sync"'
    "  0、退出")
### 配置 ####
bdbook="共享文件夹/法律电子书（持续更新）"   #百度网盘书库位置
onebook="法律书库"   #onedrive书库位置

### 将baidu同步给onedrive ###
function baidutoone {
   echo "正在清除alist文件目录缓存..."
   systemctl restart alist; sleep 15
   read -p "请输入要同步给Onedrive的Baidu网盘文件夹路径" bdname
   read -p "请输入Onedrive保存位置路径" onename
     echo "正在获取百度网盘文件夹基本信息..."
   echo "百度网盘 $bdname 文件夹基本信息如下："
   rclone size baidu:$bdname
   echo "正在获取Onedrive文件夹基本信息..."
   echo "Onedrive $onename 文件夹基本信息如下："
   rclone size onedrive:$onename
   notifier "网盘文件信息已获取，请返回操作系统确认！"
   if confirm "是否确认继续同步？" "已取消同步！"; then return 0; fi
   echo "同步中...已将同步程序置于后台"
   rclone sync baidu:$bdname --header "Referer:"  --header "User-Agent:pan.baidu.com" onedrive:$onename -P #  更改百度网盘的UA，加速作用。 --header "Referer:"  --header "User-Agent:pan.baidu.com"
   echo "同步完成..."
   notifier "baidu to one 已同步完成"
}

### 将onedrive同步给baidu ###
function onetobaidu {
   echo "正在清除alist文件目录缓存..."
   systemctl restart alist; sleep 15
   read -p "请输入要同步给Baidu网盘的Onedrive文件夹路径" bdname
   read -p "请输入Baidu网盘保存位置路径" onename
     echo "正在获取百度网盘文件夹基本信息..."
   echo "百度网盘 $bdname 文件夹基本信息如下："
   rclone size baidu:$bdname
   echo "正在获取Onedrive文件夹基本信息..."
   echo "Onedrive $onename 文件夹基本信息如下："
   rclone size onedrive:$onename
   notifier "网盘文件信息已获取，请返回操作系统确认！"
   if confirm "是否确认继续同步？" "已取消同步！"; then return 0; fi
   echo "同步中..."
   rclone sync onedrive:$onename baidu:$bdname --header "Referer:"  --header "User-Agent:pan.baidu.com" -P 
   echo "同步完成..."
   notifier "one to baidu 已同步完成"
}
### 将baidu书库给onedrive ###
function baidutoonebook {
   echo "正在清除alist文件目录缓存..."
   systemctl restart alist; sleep 15
     echo "正在获取百度网盘文件夹基本信息..."
   echo "百度网盘 $bdbook 文件夹基本信息如下："
   rclone size baidu:$bdbook
   echo "正在获取Onedrive文件夹基本信息..."
   echo "Onedrive $onebook 文件夹基本信息如下："
   rclone size onedrive:$onebook
   notifier "网盘文件信息已获取，请返回操作系统确认！"
   if confirm "是否确认继续同步？" "已取消同步！"; then return 0; fi
   echo "同步中..."
   rclone sync baidu:$bdbook --header "Referer:"  --header "User-Agent:pan.baidu.com" onedrive:$onebook -P
   echo "同步完成..."
   notifier "baidu to one 已同步完成"
}

### 将onedrive书库给baidu ###
function onetobaidubook {
   echo "正在清除alist文件目录缓存..."
   systemctl restart alist; sleep 15
     echo "正在获取百度网盘文件夹基本信息..."
   echo "百度网盘 $bdbook 文件夹基本信息如下："
   rclone size baidu:$bdbook
   echo "正在获取Onedrive文件夹基本信息..."
   echo "Onedrive $onebook 文件夹基本信息如下："
   rclone size onedrive:$onebook
   notifier "网盘文件信息已获取，请返回操作系统确认！"
   if confirm "是否确认继续同步？" "已取消同步！"; then return 0; fi
   echo "同步中..."
   rclone sync onedrive:$onebook baidu:$bdbook --header "Referer:"  --header "User-Agent:pan.baidu.com" -P
   echo "同步完成..."
   notifier "one to baidu 已同步完成"
}


#############################################################################################################################################################################################
##############################################################################   在更新检查及错误检查后，执行主函数  ################################################################################################
############################################################################################################################################################################################
main