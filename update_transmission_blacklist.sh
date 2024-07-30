#!/bin/sh

# 设置变量
host="127.0.0.1"
port="9091"
username="用户名"
password="密码"

# 更新 Transmission 黑名单
echo "更新 Transmission 黑名单..."
transmission-remote $host:$port --auth $username:$password --blocklist-update

if [ $? -eq 0 ]; then
    echo "Transmission 黑名单更新成功,重启transmission"
    /etc/init.d/transmission restart
else
    echo "更新 Transmission 黑名单失败."
fi