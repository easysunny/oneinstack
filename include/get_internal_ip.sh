#!/bin/bash

# ==============================================================================
# Script Name:   get_internal_ip.sh
# Description:   获取本机的主要内网IPv4地址，排除了127.0.0.1。
#                (This script retrieves the primary internal IPv4 address of
#                the machine, excluding 127.0.0.1.)
#
# Compatibility:
#   - CentOS / RedHat 7+
#   - Debian 9+
#   - Ubuntu 16+
# ==============================================================================

function get_ip() {
    local ip_address

    # 方法一：使用 'ip route' (首选方法)
    # 通过查询到达一个公共DNS（如 8.8.8.8）的路由，来找出本机用于对外通信的源IP地址。
    # 这是最可靠的方法，因为它能准确找到那个“主要”的IP。
    # Method 1: Use 'ip route' (Preferred).
    # This determines the source IP used to reach an external address (e.g., 8.8.8.8).
    # It's the most reliable way to find the "main" network-facing IP.
    ip_address=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | tr -d '\n')

    # 如果方法一失败，则尝试方法二。
    # If Method 1 fails, try Method 2.
    if [ -z "$ip_address" ]; then
        # 方法二：回退方案，解析 'ip addr'
        # 它会列出所有网络接口的IPv4地址，并返回第一个非回环地址。
        # Method 2: Fallback by parsing 'ip addr'.
        # It lists all IPv4 addresses and returns the first non-loopback address found.
        ip_address=$(ip -4 addr show | grep "inet" | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1 | head -n 1)
    fi

    echo "$ip_address"
}


function get_country() {
    local timezone
    local country

    # 方法一：使用 timedatectl (适用于 systemd 系统)
    # Method 1: Use timedatectl (for systemd systems)
    if command -v timedatectl &> /dev/null; then
        timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    # 方法二：读取 /etc/timezone 文件 (备用方法)
    # Method 2: Read the /etc/timezone file (fallback)
    elif [ -f /etc/timezone ]; then
        timezone=$(cat /etc/timezone)
    else
        # 如果无法确定时区，直接返回默认值
        echo "China"
        return 0
    fi

    # 注意：这是一个基于常见时区的不精确估算。
    # Note: This is an approximation based on common timezones.
    case "$timezone" in
        Asia/Shanghai|Asia/Chongqing|Asia/Harbin|Asia/Urumqi)
            country="China"
            ;;
        America/New_York|America/Chicago|America/Denver|America/Los_Angeles)
            country="United States"
            ;;
        Europe/London)
            country="United Kingdom"
            ;;
        Europe/Paris)
            country="France"
            ;;
        Europe/Berlin)
            country="Germany"
            ;;
        Asia/Tokyo)
            country="Japan"
            ;;
        Asia/Seoul)
            country="South Korea"
            ;;
        Australia/Sydney)
            country="Australia"
            ;;
        *)
            # 对于任何未明确列出的时区，默认返回 "China"。
            # For any timezone not explicitly listed, default to "China".
            country="China"
            ;;
    esac

    echo "$country"
}