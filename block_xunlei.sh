#!/bin/sh

# 显示当前日期和时间
echo "当前日期和时间: $(date)"

# 定义变量：用户名、密码、主机地址和端口
username="用户名"
password="密码"
host="127.0.0.1"
port=9091
chain="OUTPUT"  # 定义主链名称
custom_chain_ipv4="CUSTOM_CHAIN_IPV4"  # 定义IPv4自定义链名称
custom_chain_ipv6="CUSTOM_CHAIN_IPV6"  # 定义IPv6自定义链名称

# 获取所有传输任务的对等节点IP地址
echo "获取传输任务对等节点的IP地址..."
ips=$(transmission-remote $host:$port --auth $username:$password -t all --info-peers)
echo "获取的IP地址: $ips"

# 获取当前分钟和小时
minute=$(date "+%M")
hour=$(date "+%H")

# 如果当前时间是每4小时的半小时（例如，0:30，4:30等）
if [ "$minute" -eq 30 ] && [ $(($hour % 4)) -eq 0 ]; then
    echo "当前时间是每4小时的半小时, 清空自定义链 $custom_chain_ipv4 和 $custom_chain_ipv6"
    iptables -F $custom_chain_ipv4  # 清空IPv4自定义链
    ip6tables -F $custom_chain_ipv6  # 清空IPv6自定义链
fi

# 检查并创建自定义链（如果不存在）
echo "检查并创建自定义链（如果不存在）..."
iptables -L $custom_chain_ipv4 &> /dev/null || (echo "创建IPv4自定义链 $custom_chain_ipv4"; iptables -N $custom_chain_ipv4)
ip6tables -L $custom_chain_ipv6 &> /dev/null || (echo "创建IPv6自定义链 $custom_chain_ipv6"; ip6tables -N $custom_chain_ipv6)

# 确保自定义链在主链中被调用
echo "确保自定义链在主链中被调用..."
iptables -C $chain -j $custom_chain_ipv4 &> /dev/null || (echo "添加 $custom_chain_ipv4 到 $chain"; iptables -A $chain -j $custom_chain_ipv4)
ip6tables -C $chain -j $custom_chain_ipv6 &> /dev/null || (echo "添加 $custom_chain_ipv6 到 $chain"; ip6tables -A $chain -j $custom_chain_ipv6)

# 获取当前的自定义链规则
echo "获取当前自定义链规则..."
ipv4_rules=$(iptables -nL $custom_chain_ipv4)
ipv6_rules=$(ip6tables -nL $custom_chain_ipv6)
echo "当前IPv4自定义链规则: $ipv4_rules"
echo "当前IPv6自定义链规则: $ipv6_rules"

# 检查是否为私有 IPv4 地址
is_private_ipv4() {
    local ip=$1
    # Check for private IPv4 addresses
    ipcalc -n $ip | grep -q 'Network: 10.0.0.0/8\|172.16.0.0/12\|192.168.0.0/16'
}

# 检查是否为私有 IPv6 地址
is_private_ipv6() {
    local ip=$1
    # Check for private IPv6 addresses
    echo $ip | grep -qE '^fc00:|^fd00:|^fe80:'
}

# 遍历指定的客户端名称
for client in xunlei xl thunder gt0002 xl0012 xfplay dandanplay dl3760 qq hp dt xm go taibei sp StellarPlayer flashget torrentstorm github ljyun cacao "-tt" "qbittorrent/3.3.15"
do
    echo -n "处理客户端 $client: "  # 输出正在处理的客户端名称
    # 获取与当前客户端匹配的IP地址
    for i in $(echo "$ips" | grep -F -i --  "$client" | cut -d " " -f 1)
    do
        # 检查当前IP是否已经在规则中
        if echo "$ipv4_rules" | grep -q $i || echo "$ipv6_rules" | grep -q $i; then
            echo -n "$i 已在规则中, "  # 如果在规则中，输出IP
        else
            echo -n "$i 不在规则中, "  # 如果不在规则中，输出IP并说明未在规则中
            # 检查是否为IPv6地址
            if echo "$i" | grep -q ":" ; then
                # 如果是IPv6地址，检查是否为私有地址
                if is_private_ipv6 $i; then
                    echo "$i 是私有IPv6地址, 忽略."
                else
                    # 如果是IPv6地址，添加DROP规则到IPv6自定义链
                    echo "添加IPv6地址 $i 到自定义链 $custom_chain_ipv6"
                    ip6tables -I $custom_chain_ipv6 -d $i -j DROP
                fi
            else
                # 如果是IPv4地址，检查是否为私有地址
                if is_private_ipv4 $i; then
                    echo "$i 是私有IPv4地址, 忽略."
                else
                    # 如果是IPv4地址，添加DROP规则到IPv4自定义链
                    echo "添加IPv4地址 $i 到自定义链 $custom_chain_ipv4"
                    iptables -I $custom_chain_ipv4 -d $i -j DROP
                fi
            fi
        fi
    done
    echo ""  # 输出换行符
done

echo "脚本执行完毕."