# openwrt屏蔽吸血客户端和 pcdn ip段

> 为transmisson屏蔽迅雷等吸血客户端

[教程地址](https://github.com/jqtmviyu/BTN-Collected-Rules)


## 防火墙阻止吸血客户端

1. 创建脚本

修改自 [WhymustIhaveaname/Transmission-Block-Xunlei](https://github.com/WhymustIhaveaname/Transmission-Block-Xunlei)

因为是在openwrt中运行,所以有点不太一样

```sh
#!/bin/sh

# 显示当前日期和时间
echo "当前日期和时间: $(date)"

# 定义变量：用户名、密码、主机地址和端口
username="用户名"
password="密码"
host="127.0.0.1"
port=9091
ipv4_chain="OUTPUT"  # 定义IPv4主链名称
ipv6_chain="OUTPUT"  # 定义IPv6主链名称
ipv4_custom_chain="CUSTOM_CHAIN_IPV4"  # 定义IPv4自定义链名称
ipv6_custom_chain="CUSTOM_CHAIN_IPV6"  # 定义IPv6自定义链名称

# 获取所有传输任务的对等节点IP地址
echo "获取传输任务对等节点的IP地址..."
ips=$(transmission-remote $host:$port --auth $username:$password -t all --info-peers)
echo "获取的IP地址: $ips"

# 获取当前分钟和小时
minute=$(date "+%M")
hour=$(date "+%H")

# 如果当前时间是每4小时的半小时（例如，0:30，4:30等）
if [ "$minute" -eq 30 ] && [ $(($hour % 4)) -eq 0 ]; then
    echo "当前时间是每4小时的半小时, 清空自定义链 $ipv4_custom_chain 和 $ipv6_custom_chain"
    iptables -F $ipv4_custom_chain  # 清空IPv4自定义链
    ip6tables -F $ipv6_custom_chain  # 清空IPv6自定义链
fi

# 检查并创建自定义链（如果不存在）
echo "检查并创建自定义链（如果不存在）..."
iptables -L $ipv4_custom_chain &> /dev/null || (echo "创建IPv4自定义链 $ipv4_custom_chain"; iptables -N $ipv4_custom_chain)
ip6tables -L $ipv6_custom_chain &> /dev/null || (echo "创建IPv6自定义链 $ipv6_custom_chain"; ip6tables -N $ipv6_custom_chain)

# 确保自定义链在主链中被调用
echo "确保自定义链在主链中被调用..."
iptables -C $ipv4_chain -j $ipv4_custom_chain &> /dev/null || (echo "添加 $ipv4_custom_chain 到 $ipv4_chain"; iptables -A $ipv4_chain -j $ipv4_custom_chain)
ip6tables -C $ipv6_chain -j $ipv6_custom_chain &> /dev/null || (echo "添加 $ipv6_custom_chain 到 $ipv6_chain"; ip6tables -A $ipv6_chain -j $ipv6_custom_chain)

# 获取当前的自定义链规则
echo "获取当前自定义链规则..."
ipv4_rules=$(iptables -nL $ipv4_custom_chain)
ipv6_rules=$(ip6tables -nL $ipv6_custom_chain)
echo "当前IPv4自定义链规则: $ipv4_rules"
echo "当前IPv6自定义链规则: $ipv6_rules"

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
                # 如果是IPv6地址，添加DROP规则到IPv6自定义链
                echo "添加IPv6地址 $i 到自定义链 $ipv6_custom_chain"
                ip6tables -I $ipv6_custom_chain -d $i -j DROP
            else
                # 如果是IPv4地址，添加DROP规则到IPv4自定义链
                echo "添加IPv4地址 $i 到自定义链 $ipv4_custom_chain"
                iptables -I $ipv4_custom_chain -d $i -j DROP
            fi
        fi
    done
    echo ""  # 输出换行符
done

echo "脚本执行完毕."
```

2. 添加计划任务

每两分钟运行一次

```crontab
PATH=/usr/sbin:/usr/bin:/sbin:/bin
*/2 * * * * /root/block_xunlei.sh 2>> /root/block_xunlei.log
```

## 添加屏蔽url

修改自 [PBH-BTN/BTN-Collected-Rules](https://github.com/PBH-BTN/BTN-Collected-Rules) 的all.txt

github action 每天自动更新

`transmission_blacklist.gz` 体积更小, 下载更快.

### 定时更新

```sh
#!/bin/sh

# 设置变量
HOST="127.0.0.1"
PORT="9091"
USERNAME="用户名"
PASSWORD="密码"

# 更新 Transmission 黑名单
echo "更新 Transmission 黑名单..."
transmission-remote $HOST:$PORT --auth $USERNAME:$PASSWORD --blocklist-update

if [ $? -eq 0 ]; then
    echo "Transmission 黑名单更新成功,重启transmission"
    /etc/init.d/transmission restart
else
    echo "更新 Transmission 黑名单失败."
fi
```

```crontab
0 5 * * * /root/update_transmission_blacklist.sh 2>> /root/block_xunlei.log
```