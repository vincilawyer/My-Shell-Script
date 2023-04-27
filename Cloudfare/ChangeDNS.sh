#!/bin/bash

# 设置变量
email="15555@qq.com"
domain="16666.com"
api_key="177777"

# 获取区域标识符
zone_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
     -H "X-Auth-Email: $email" \
     -H "X-Auth-Key: $api_key" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# 如果区域标识符为空，则表示未找到该域名
if [ "$zone_identifier" == "null" ]; then
    echo "未找到您的Cloudflare账户\域名，请检查配置。"
    exit 0
fi
   # 获取所有DNS解析记录、CDN代理状态和TTL
   function get_all_dns_records {
    dns_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A" \
         -H "X-Auth-Email: $email" \
         -H "X-Auth-Key: $api_key" \
         -H "Content-Type: application/json" | jq -r '.result[] | [.name, .content, .proxied, .ttl] | @tsv')
   }
         
  # 显示所有DNS解析记录、CDN代理状态和TTL
   function all_dns_records {
       echo "——————————DNS解析编辑器v1————————————"
       echo "以下为$domain域名当前的所有DNS解析记录："
       echo
       echo "域名                      ip        CDN状态      TTL"
       echo "$dns_records"
       echo
       echo
   }
    get_all_dns_records
    all_dns_records
    # 询问用户要进行的操作
    echo "操作选项："
    echo "1. 删除DNS记录"
    echo "2. 修改或增加DNS记录"
    echo "3、www域名一键绑定本机ip（开启CDN）"
    read -p "请选择要进行的操作：" choice
    case $choice in
      1)
        # 删除DNS记录
        clear
        all_dns_records
        read -p "请输入要删除的DNS记录名称（例如 www）：" record_name

        # 获取记录标识符
        record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name.$domain" \
             -H "X-Auth-Email: $email" \
             -H "X-Auth-Key: $api_key" \
             -H "Content-Type: application/json" | jq -r '.result[0].id')
        
        clear
        # 如果记录标识符为空，则表示未找到该记录
        if [ "$record_identifier" == "null" ]; then
            echo "未找到该DNS记录。"
        else
            # 删除记录
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                 -H "X-Auth-Email: $email" \
                 -H "X-Auth-Key: $api_key" \
                 -H "Content-Type: application/json"
            echo
            echo "已成功删除DNS记录: $record_name.$domain"
            get_all_dns_records
            all_dns_records
        fi;;
     2)
        # 修改或增加DNS记录
        clear
        all_dns_records
        read -p "请输入要修改或增加的DNS记录名称（例如 www）：" record_name

        # 验证IP地址
        ip_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
        while true; do
            read -p "请输入IP地址：" record_content
            if [[ $record_content =~ $ip_regex ]]; then
                break
            else
                echo "无效的IP地址，请重试。"
            fi
        done
        read -p "是否启用Cloudflare CDN代理？（Y/N）" enable_proxy
        if [[ $enable_proxy =~ ^[Yy]$ ]]; then
            proxy="true"
        else
            proxy="false"
        fi

            # 获取记录标识符
            record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name.$domain" \
                 -H "X-Auth-Email: $email" \
                 -H "X-Auth-Key: $api_key" \
                 -H "Content-Type: application/json" | jq -r '.result[0].id')
            clear 
            # 如果记录标识符为空，则创建新记录
            if [ "$record_identifier" == "null" ]; then
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" \
                     -H "X-Auth-Email: $email" \
                     -H "X-Auth-Key: $api_key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'"$record_name"'","content":"'"$record_content"'","proxied":'"$proxy"'}'
                echo
                echo "已成功添加记录 $record_name.$domain"
                get_all_dns_records
                all_dns_records
            else
                # 如果记录标识符不为空，则更新现有记录
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                     -H "X-Auth-Email: $email" \
                     -H "X-Auth-Key: $api_key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'"$record_name"'","content":"'"$record_content"'","proxied":'"$proxy"'}'
                echo
                echo "已成功更新记录 $record_name.$domain"
                get_all_dns_records
                all_dns_records
           fi;;
     3)
          record_name="www"
          record_content=$(ip addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1)
          proxy="true"
           # 获取记录标识符
            record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=A&name=$record_name.$domain" \
                 -H "X-Auth-Email: $email" \
                 -H "X-Auth-Key: $api_key" \
                 -H "Content-Type: application/json" | jq -r '.result[0].id')
            clear 
            # 如果记录标识符为空，则创建新记录
            if [ "$record_identifier" == "null" ]; then
                curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" \
                     -H "X-Auth-Email: $email" \
                     -H "X-Auth-Key: $api_key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'"$record_name"'","content":"'"$record_content"'","proxied":'"$proxy"'}'
                echo
                echo "已成功添加记录 $record_name.$domain"
                get_all_dns_records
                all_dns_records
            else
                # 如果记录标识符不为空，则更新现有记录
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
                     -H "X-Auth-Email: $email" \
                     -H "X-Auth-Key: $api_key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'"$record_name"'","content":"'"$record_content"'","proxied":'"$proxy"'}'
                echo
                echo "已成功更新记录 $record_name.$domain"
                get_all_dns_records
                all_dns_records
           fi    
    *) echo "输入错误，已取消操作！";;
  esac
