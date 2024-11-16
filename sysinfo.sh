#!/bin/sh

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LANG=zh_CN.UTF-8

SHOW_IP_PATTERN="^[ewr].*|^br.*|^lt.*|^umts.*"

# 获取 IP 地址
get_ip_addresses() {
    for f in /sys/class/net/*; do
        intf=$(basename $f)
        if echo "$intf" | grep -Eq "$SHOW_IP_PATTERN"; then
            ip=$(ip -4 addr show dev "$intf" | awk '/inet/ {print $2}' | cut -d'/' -f1)
            if [ -n "$ip" ]; then
                echo "$ip"
            fi
        fi
    done
}

# 获取存储信息
storage_info() {
    RootInfo=$(df -h /)
    root_usage=$(echo "$RootInfo" | awk '/\// {print $(NF-1)}' | sed 's/%//g')
    root_total=$(echo "$RootInfo" | awk '/\// {print $(NF-4)}')
}

# 获取负载、运行时间和内存信息
storage_info
critical_load=$(( 1 + $(grep -c processor /proc/cpuinfo) / 2 ))

UptimeString=$(uptime | tr -d ',')
time=$(echo "$UptimeString" | awk -F" " '{print $3" "$4}')
load=$(echo "$UptimeString" | awk -F"average: " '{print $2}')
case ${time} in
    1:*) 
        time=$(echo "$UptimeString" | awk '{print $3" 小时"}')
        ;;
    *:*) 
        time=$(echo "$UptimeString" | awk '{print $3" 小时"}')
        ;;
    *day) 
        days=$(echo "$UptimeString" | awk '{print $3"天"}')
        time=$(echo "$UptimeString" | awk '{print $5}')
        time="$days $(echo "$time" | awk -F":" '{print $1"小时 "$2"分钟"}')"
        ;;
esac

mem_info=$(free | grep "^Mem")
memory_usage=$(echo "$mem_info" | awk '{printf("%.0f",(($2-($4+$6))/$2) * 100)}')
memory_total=$(echo "$mem_info" | awk '{printf("%d",$2/1024)}')

swap_info=$(free -m | grep "^Swap")
swap_usage=$(echo "$swap_info" | awk '{if ($2 > 0) printf("%3.0f", $3/$2*100); else print 0}')
swap_total=$(echo "$swap_info" | awk '{print $2}')

ip_address=$(get_ip_addresses)

# 获取 CPU 信息
cpu_model=$(grep "model name" /proc/cpuinfo | uniq | awk -F: '{print $2}' | sed 's/^ //')
cpu_cores=$(grep -c processor /proc/cpuinfo)

# 获取 CoreMark 跑分信息
coremark_file="/etc/bench.log"
if [ -f "$coremark_file" ]; then
    coremark_score=$(grep "CpuMark" "$coremark_file" | awk -F: '{print $2}' | awk '{print $1}')
    coremark_score="${coremark_score:-未运行请等待}"
else
    coremark_score="未运行       "
fi

# 显示系统信息
printf "%-15s%-15s\n" "---------------------------------" "---------------------------------"
printf "%-15s %-10s\t%-15s %-10s\n" "系统负载:" "$load" "运行时间:" "$time"
printf "%-15s %-10s\t%-15s %-10s\n" "内存已用:" "${memory_usage}% of ${memory_total}MB" "交换内存:" "${swap_usage}% of ${swap_total}MB"
printf "%-11s %-8s\t%-15s %-10s\n" "CoreMark:" "$coremark_score" "存储使用:" "${root_usage}% of ${root_total}"
printf "%-13s %-10s\t%-13s %-10s\n" "IP地址:" "$ip_address" "CPU 型号:" "$cpu_model"
printf "%-15s%-15s\n" "---------------------------------" "---------------------------------"
