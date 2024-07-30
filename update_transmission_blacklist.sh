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